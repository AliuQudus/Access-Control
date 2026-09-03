table 70103 "User Access Line"
{
    Caption = 'User Access Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User';
            TableRelation = "User Access Header"."User Security ID";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            AutoIncrement = true;
        }
        field(10; "Company Name"; Text[30])
        {
            Caption = 'Company';
            TableRelation = Company.Name;
            // Left blank intentionally means "all companies" - mirrors the native
            // Access Control behavior where a blank Company Name is a global grant.
            // If you want to disallow that in your org, set NotBlank = true here instead.
        }
        field(20; "Bundle Code"; Code[20])
        {
            Caption = 'Access Bundle';
            TableRelation = "Access Bundle".Code;
            NotBlank = true;
        }
        field(21; "Bundle Description"; Text[100])
        {
            Caption = 'Bundle Description';
            FieldClass = FlowField;
            CalcFormula = lookup("Access Bundle".Description where(Code = field("Bundle Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "User Security ID", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    begin
        // Removing a line doesn't retroactively strip Access Control on its own;
        // that only happens the next time SyncUserAccess runs for this user.
        // Consider prompting the caller to re-sync from the page action.
    end;
}
