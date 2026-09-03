codeunit 70100 "Access Sync Mgt."
{
    Permissions = tabledata "Access Control" = rimd,
                  tabledata "User Personalization" = rm,
                  tabledata "Tenant Permission Set" = rimd,
                  tabledata "Tenant Permission" = rimd;

    procedure SyncUserAccess(UserSecurityId: Guid)
    var
        TempDesired: Record "Managed Access Entry" temporary;
    begin
        BuildDesiredEntries(UserSecurityId, TempDesired);
        ApplyDesiredEntries(UserSecurityId, TempDesired);
        UpdateLastSynchronized(UserSecurityId);
    end;

    procedure SyncAllUsers()
    var
        UserAccessHeader: Record "User Access Header";
    begin
        if UserAccessHeader.FindSet() then
            repeat
                SyncUserAccess(UserAccessHeader."User Security ID");
                ApplyRoleCenter(
                    UserAccessHeader."User Security ID",
                    UserAccessHeader."Default Role Center Profile ID",
                    UserAccessHeader."Default Role Center App ID");
            until UserAccessHeader.Next() = 0;
    end;

    procedure ApplyRoleCenter(UserSecurityId: Guid; ProfileId: Code[30]; ProfileAppId: Guid)
    var
        UserPersonalization: Record "User Personalization";
    begin
        if ProfileId = '' then
            exit;

        if not UserPersonalization.Get(UserSecurityId) then begin
            UserPersonalization."User SID" := UserSecurityId;
            UserPersonalization.Insert();
        end;

        UserPersonalization.Validate("Profile ID", ProfileId);
        UserPersonalization.Validate("App ID", ProfileAppId);
        UserPersonalization.Modify(true);
    end;

    local procedure BuildDesiredEntries(UserSecurityId: Guid; var TempDesired: Record "Managed Access Entry" temporary)
    var
        UserAccessLine: Record "User Access Line";
        AccessBundleLine: Record "Access Bundle Line";
        AccessBundle: Record "Access Bundle";
    begin
        TempDesired.Reset();
        TempDesired.DeleteAll();

        UserAccessLine.SetRange("User Security ID", UserSecurityId);
        if not UserAccessLine.FindSet() then
            exit;

        repeat
            // Permission-set lines: grant each native/tenant permission set directly.
            AccessBundleLine.SetRange("Bundle Code", UserAccessLine."Bundle Code");
            AccessBundleLine.SetRange("Line Type", AccessBundleLine."Line Type"::"Permission Set");
            if AccessBundleLine.FindSet() then
                repeat
                    TempDesired."User Security ID" := UserSecurityId;
                    TempDesired."Company Name" := UserAccessLine."Company Name";
                    TempDesired."Permission Set ID" := AccessBundleLine."Permission Set ID";
                    TempDesired.Scope := AccessBundleLine.Scope;
                    TempDesired."App ID" := GetAppId(AccessBundleLine."Permission Set ID", AccessBundleLine.Scope);
                    if TempDesired.Insert() then;
                until AccessBundleLine.Next() = 0;

            // Object lines: compiled into one generated permission set per group,
            // rebuilt fresh here so edits to the group are picked up on next sync.
            AccessBundleLine.SetRange("Line Type", AccessBundleLine."Line Type"::"Object");
            if not AccessBundleLine.IsEmpty() then begin
                AccessBundle.Get(UserAccessLine."Bundle Code");
                EnsureGroupPermissionSet(AccessBundle.Code, AccessBundle.Description);

                TempDesired."User Security ID" := UserSecurityId;
                TempDesired."Company Name" := UserAccessLine."Company Name";
                TempDesired."Permission Set ID" := AccessBundle.Code;
                TempDesired.Scope := TempDesired.Scope::Tenant;
                TempDesired."App ID" := GetExtensionAppId();
                if TempDesired.Insert() then;
            end;
        until UserAccessLine.Next() = 0;
    end;

    /// <summary>
    /// Compiles every Object-type line in the given group into a Tenant Permission Set that
    /// this tool owns exclusively (Role ID = group code, App ID = this extension). Safe to call
    /// repeatedly - fully rebuilds the permission rows from the group's current lines each time.
    /// </summary>
    procedure EnsureGroupPermissionSet(BundleCode: Code[20]; BundleDescription: Text[100])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        AccessBundleLine: Record "Access Bundle Line";
        AppId: Guid;
    begin
        AppId := GetExtensionAppId();

        if not TenantPermissionSet.Get(AppId, BundleCode) then begin
            TenantPermissionSet."App ID" := AppId;
            TenantPermissionSet."Role ID" := BundleCode;
            TenantPermissionSet.Assignable := false; // internal - assigned only via Access Control by this tool
            TenantPermissionSet.Insert();
        end;
        TenantPermissionSet.Name := CopyStr(BundleDescription, 1, MaxStrLen(TenantPermissionSet.Name));
        TenantPermissionSet.Modify();

        TenantPermission.SetRange("App ID", AppId);
        TenantPermission.SetRange("Role ID", BundleCode);
        TenantPermission.DeleteAll();

        AccessBundleLine.SetRange("Bundle Code", BundleCode);
        AccessBundleLine.SetRange("Line Type", AccessBundleLine."Line Type"::"Object");
        if AccessBundleLine.FindSet() then
            repeat
                TenantPermission.Init();
                TenantPermission."App ID" := AppId;
                TenantPermission."Role ID" := BundleCode;
                TenantPermission."Object ID" := AccessBundleLine."Object ID";
                TenantPermission.Type := TenantPermission.Type::Include;

                // Every permission option defaults to Yes on Init (per the platform's own
                // InitValue) - explicitly blank the ones we do NOT want, don't just leave them.
                TenantPermission."Read Permission" := TenantPermission."Read Permission"::" ";
                TenantPermission."Insert Permission" := TenantPermission."Insert Permission"::" ";
                TenantPermission."Modify Permission" := TenantPermission."Modify Permission"::" ";
                TenantPermission."Delete Permission" := TenantPermission."Delete Permission"::" ";
                TenantPermission."Execute Permission" := TenantPermission."Execute Permission"::" ";

                case AccessBundleLine."Object Type" of
                    AccessBundleLine."Object Type"::Table:
                        begin
                            TenantPermission."Object Type" := TenantPermission."Object Type"::"Table Data";
                            if AccessBundleLine."Allow View" then
                                TenantPermission."Read Permission" := TenantPermission."Read Permission"::Yes;
                            if AccessBundleLine."Allow Insert" then
                                TenantPermission."Insert Permission" := TenantPermission."Insert Permission"::Yes;
                            if AccessBundleLine."Allow Modify" then
                                TenantPermission."Modify Permission" := TenantPermission."Modify Permission"::Yes;
                            if AccessBundleLine."Allow Delete" then
                                TenantPermission."Delete Permission" := TenantPermission."Delete Permission"::Yes;
                        end;
                    AccessBundleLine."Object Type"::Page:
                        begin
                            TenantPermission."Object Type" := TenantPermission."Object Type"::Page;
                            if AccessBundleLine."Allow View" then
                                TenantPermission."Execute Permission" := TenantPermission."Execute Permission"::Yes;
                        end;
                end;

                TenantPermission.Insert();
            until AccessBundleLine.Next() = 0;
    end;

    local procedure GetExtensionAppId(): Guid
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        exit(CurrentModuleInfo.Id());
    end;

    local procedure ApplyDesiredEntries(UserSecurityId: Guid; var TempDesired: Record "Managed Access Entry" temporary)
    var
        ManagedAccessEntry: Record "Managed Access Entry";
    begin
        // Grant anything desired that isn't already granted.
        if TempDesired.FindSet() then
            repeat
                if not ManagedAccessEntry.Get(
                    UserSecurityId, TempDesired."Company Name", TempDesired."Permission Set ID", TempDesired.Scope, TempDesired."App ID")
                then
                    GrantAccessControl(
                        UserSecurityId, TempDesired."Company Name", TempDesired."Permission Set ID",
                        TempDesired.Scope, TempDesired."App ID");
            until TempDesired.Next() = 0;

        // Revoke anything previously managed that's no longer desired.
        ManagedAccessEntry.SetRange("User Security ID", UserSecurityId);
        if ManagedAccessEntry.FindSet() then
            repeat
                TempDesired.SetRange("Company Name", ManagedAccessEntry."Company Name");
                TempDesired.SetRange("Permission Set ID", ManagedAccessEntry."Permission Set ID");
                TempDesired.SetRange(Scope, ManagedAccessEntry.Scope);
                TempDesired.SetRange("App ID", ManagedAccessEntry."App ID");
                if TempDesired.IsEmpty() then
                    RevokeAccessControl(
                        UserSecurityId, ManagedAccessEntry."Company Name",
                        ManagedAccessEntry."Permission Set ID", ManagedAccessEntry.Scope, ManagedAccessEntry."App ID");
            until ManagedAccessEntry.Next() = 0;
    end;

    local procedure GrantAccessControl(UserSecurityId: Guid; CompanyName: Text[30]; PermissionSetId: Code[20]; Scope: Enum "Access Bundle Perm. Scope"; AppId: Guid)
    var
        AccessControl: Record "Access Control";
        ManagedAccessEntry: Record "Managed Access Entry";
    begin
        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId;
        AccessControl."Role ID" := PermissionSetId;
        AccessControl."Company Name" := CompanyName;
        AccessControl.Scope := ScopeToSystemScope(Scope);
        AccessControl."App ID" := AppId;
        if AccessControl.Insert(true) then begin
            ManagedAccessEntry."User Security ID" := UserSecurityId;
            ManagedAccessEntry."Company Name" := CompanyName;
            ManagedAccessEntry."Permission Set ID" := PermissionSetId;
            ManagedAccessEntry.Scope := Scope;
            ManagedAccessEntry."App ID" := AppId;
            ManagedAccessEntry.Insert();
        end;
    end;

    local procedure RevokeAccessControl(UserSecurityId: Guid; CompanyName: Text[30]; PermissionSetId: Code[20]; Scope: Enum "Access Bundle Perm. Scope"; AppId: Guid)
    var
        AccessControl: Record "Access Control";
        ManagedAccessEntry: Record "Managed Access Entry";
    begin
        if AccessControl.Get(UserSecurityId, PermissionSetId, CompanyName, ScopeToSystemScope(Scope), AppId) then
            AccessControl.Delete(true);

        if ManagedAccessEntry.Get(UserSecurityId, CompanyName, PermissionSetId, Scope, AppId) then
            ManagedAccessEntry.Delete();
    end;

    local procedure GetAppId(PermissionSetId: Code[20]; Scope: Enum "Access Bundle Perm. Scope") AppId: Guid
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange("Role ID", PermissionSetId);
        AggregatePermissionSet.SetRange(Scope, ScopeToSystemScope(Scope));
        if AggregatePermissionSet.FindFirst() then
            AppId := AggregatePermissionSet."App ID";
    end;

    local procedure ScopeToSystemScope(Scope: Enum "Access Bundle Perm. Scope") SystemScope: Option System,Tenant
    begin
        // Access Control's own Scope field is a platform Option, not our enum -
        // translate at the boundary rather than fighting the platform type.
        case Scope of
            Scope::"System":
                exit(SystemScope::System);
            Scope::Tenant:
                exit(SystemScope::Tenant);
        end;
    end;

    /// <summary>
    /// Read-only scan of native Access Control for this user, independent of any sync.
    /// Flags SUPER (from any source) and counts grants this tool did not create.
    /// Does not remove or alter anything - detection only, by design.
    /// </summary>
    procedure CheckExternalAccess(UserSecurityId: Guid)
    var
        AccessControl: Record "Access Control";
        ManagedAccessEntry: Record "Managed Access Entry";
        UserAccessHeader: Record "User Access Header";
        HasSuper: Boolean;
        ExternalCount: Integer;
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId);
        if AccessControl.FindSet() then
            repeat
                if UpperCase(AccessControl."Role ID") = 'SUPER' then
                    HasSuper := true;

                if not ManagedAccessEntry.Get(
                    UserSecurityId, AccessControl."Company Name", AccessControl."Role ID",
                    SystemScopeToEnum(AccessControl.Scope), AccessControl."App ID")
                then
                    ExternalCount += 1;
            until AccessControl.Next() = 0;

        if UserAccessHeader.Get(UserSecurityId) then begin
            UserAccessHeader."Has Super Permission" := HasSuper;
            UserAccessHeader."External Access Count" := ExternalCount;
            UserAccessHeader.Modify();
        end;
    end;

    procedure SystemScopeToEnum(SystemScope: Option System,Tenant) MappedScope: Enum "Access Bundle Perm. Scope"
    begin
        case SystemScope of
            SystemScope::System:
                exit(MappedScope::"System");
            SystemScope::Tenant:
                exit(MappedScope::Tenant);
        end;
    end;

    local procedure UpdateLastSynchronized(UserSecurityId: Guid)
    var
        UserAccessHeader: Record "User Access Header";
    begin
        if UserAccessHeader.Get(UserSecurityId) then begin
            UserAccessHeader."Last Synchronized On" := CurrentDateTime();
            UserAccessHeader.Modify();
        end;
        CheckExternalAccess(UserSecurityId);
    end;
}
