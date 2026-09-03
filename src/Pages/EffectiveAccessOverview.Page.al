page 70104 "Effective Access Overview"
{
    Caption = 'Effective Access Overview';
    PageType = List;
    SourceTable = "Access Control";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(UserNameDisplay; UserNameDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'User';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    Caption = 'Company (blank = all)';
                }
                field("Role ID"; Rec."Role ID")
                {
                    ApplicationArea = All;
                    Caption = 'Permission Set';
                }
                field(Scope; Rec.Scope)
                {
                    ApplicationArea = All;
                }
                field("App Name"; Rec."App Name")
                {
                    ApplicationArea = All;
                    Caption = 'From App';
                }
                field(ManagedByThisTool; ManagedByThisTool)
                {
                    ApplicationArea = All;
                    Caption = 'Managed by Access Manager';
                    ToolTip = 'Yes if this specific grant was created by this extension and will be revoked automatically if removed from the user''s assignment.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AccessUser: Record User;
        ManagedAccessEntry: Record "Managed Access Entry";
        AccessSyncMgt: Codeunit "Access Sync Mgt.";
    begin
        if AccessUser.Get(Rec."User Security ID") then
            UserNameDisplay := AccessUser."Full Name"
        else
            UserNameDisplay := '';
        if UserNameDisplay = '' then
            UserNameDisplay := Format(Rec."User Security ID");

        ManagedByThisTool :=
            ManagedAccessEntry.Get(
                Rec."User Security ID", Rec."Company Name", Rec."Role ID",
                AccessSyncMgt.SystemScopeToEnum(Rec.Scope), Rec."App ID");
    end;

    var
        UserNameDisplay: Text[80];
        ManagedByThisTool: Boolean;
}
