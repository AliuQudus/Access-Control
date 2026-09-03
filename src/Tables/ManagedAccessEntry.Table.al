table 70104 "Managed Access Entry"
{
    Caption = 'Managed Access Entry';
    DataClassification = SystemMetadata;
    // Not user-facing. This table is the tool's memory of exactly which
    // Access Control rows it created, so SyncUserAccess only ever inserts/removes
    // rows it owns and never touches grants that came from elsewhere
    // (native User Groups, direct admin assignment, SUPER, license-based defaults).

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User';
        }
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company';
        }
        field(3; "Permission Set ID"; Code[20])
        {
            Caption = 'Permission Set ID';
        }
        field(4; Scope; Enum "Access Bundle Perm. Scope")
        {
            Caption = 'Scope';
        }
        field(5; "App ID"; Guid)
        {
            Caption = 'App ID';
        }
    }

    keys
    {
        key(PK; "User Security ID", "Company Name", "Permission Set ID", Scope, "App ID")
        {
            Clustered = true;
        }
    }
}
