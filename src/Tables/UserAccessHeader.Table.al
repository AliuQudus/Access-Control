table 70102 "User Access Header"
{
    Caption = 'User Access Assignment';
    DataClassification = CustomerContent;
    LookupPageId = "User Access List";
    DrillDownPageId = "User Access List";

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User';
            TableRelation = User."User Security ID";

            trigger OnValidate()
            begin
                CalcFields("User Name", "Full Name");
            end;
        }
        field(2; "User Name"; Code[50])
        {
            Caption = 'User Name';
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
            Editable = false;
        }
        field(3; "Full Name"; Text[80])
        {
            Caption = 'Full Name';
            FieldClass = FlowField;
            CalcFormula = lookup(User."Full Name" where("User Security ID" = field("User Security ID")));
            Editable = false;
        }
        field(10; "Default Role Center Profile ID"; Code[30])
        {
            Caption = 'Role Center';
            // "All Profile" unions System and Tenant profiles, same pattern as
            // Aggregate Permission Set above - lets the admin pick any role center
            // regardless of whether it ships from Microsoft, an app, or is custom.
            TableRelation = "All Profile"."Profile ID";

            trigger OnValidate()
            var
                AllProfile: Record "All Profile";
            begin
                if "Default Role Center Profile ID" = '' then begin
                    Clear("Default Role Center App ID");
                    exit;
                end;
                AllProfile.SetRange("Profile ID", "Default Role Center Profile ID");
                if AllProfile.FindFirst() then
                    "Default Role Center App ID" := AllProfile."App ID";
            end;
        }
        field(11; "Default Role Center App ID"; Guid)
        {
            Caption = 'Role Center App ID';
            Editable = false;
        }
        field(20; "Last Synchronized On"; DateTime)
        {
            Caption = 'Last Synchronized On';
            Editable = false;
        }
        field(21; "No. of Company Lines"; Integer)
        {
            Caption = 'No. of Companies';
            FieldClass = FlowField;
            CalcFormula = count("User Access Line" where("User Security ID" = field("User Security ID")));
            Editable = false;
        }
        field(30; "Has Super Permission"; Boolean)
        {
            Caption = 'Has SUPER (from elsewhere)';
            Editable = false;
            ToolTip = 'As of the last sync/check: this user has the SUPER permission set from somewhere other than this tool. SUPER grants full access to everything, so any groups assigned here have no practical restricting effect until this is addressed.';
        }
        field(31; "External Access Count"; Integer)
        {
            Caption = 'Other Access Grants';
            Editable = false;
            ToolTip = 'As of the last sync/check: the number of Access Control grants this user has that were NOT created by this tool - e.g. from a User Group, a license plan default, or a direct admin assignment made outside this tool.';
        }
    }

    keys
    {
        key(PK; "User Security ID")
        {
            Clustered = true;
        }
    }
}
