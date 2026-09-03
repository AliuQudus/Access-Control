table 70101 "Access Bundle Line"
{
    Caption = 'Access Group Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bundle Code"; Code[20])
        {
            Caption = 'Group Code';
            TableRelation = "Access Bundle".Code;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            AutoIncrement = true;
        }
        field(5; "Line Type"; Enum "Access Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                // Switching type clears the fields that only make sense for the other type,
                // so a half-filled row from before doesn't silently carry over.
                if "Line Type" <> xRec."Line Type" then begin
                    Validate("Permission Set ID", '');
                    Validate("Object ID", 0);
                end;
            end;
        }

        // ---- Fields used when Line Type = Permission Set ----
        field(10; "Permission Set ID"; Code[20])
        {
            Caption = 'Permission Set';
            TableRelation = "Aggregate Permission Set"."Role ID" where(Scope = field(Scope));

            trigger OnValidate()
            var
                AggregatePermissionSet: Record "Aggregate Permission Set";
            begin
                if "Permission Set ID" = '' then begin
                    "Permission Set Name" := '';
                    exit;
                end;
                "Line Type" := "Line Type"::"Permission Set";
                AggregatePermissionSet.SetRange(Scope, Scope);
                AggregatePermissionSet.SetRange("Role ID", "Permission Set ID");
                if AggregatePermissionSet.FindFirst() then
                    "Permission Set Name" := AggregatePermissionSet.Name;
            end;
        }
        field(11; "Permission Set Name"; Text[30])
        {
            Caption = 'Permission Set Name';
            Editable = false;
        }
        field(12; Scope; Enum "Access Bundle Perm. Scope")
        {
            Caption = 'Scope';

            trigger OnValidate()
            begin
                Validate("Permission Set ID", '');
            end;
        }

        // ---- Fields used when Line Type = Object ----
        field(20; "Object Type"; Enum "Access Object Type")
        {
            Caption = 'Object Type';

            trigger OnValidate()
            begin
                Validate("Object ID", 0);
            end;
        }
        field(21; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            TableRelation = AllObjWithCaption."Object ID";
            // NOTE: not filtered by Object Type here to avoid guessing AllObjWithCaption's
            // exact Object Type option values. OnValidate below checks the object genuinely
            // exists as the chosen type and blocks the entry if it doesn't.

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
                Found: Boolean;
            begin
                "Object Name" := '';
                if "Object ID" = 0 then
                    exit;

                "Line Type" := "Line Type"::"Object";

                case "Object Type" of
                    "Object Type"::Table:
                        Found := AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, "Object ID");
                    "Object Type"::Page:
                        Found := AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, "Object ID");
                end;

                if not Found then
                    Error('Object %1 was not found as a %2.', "Object ID", "Object Type");

                "Object Name" := AllObjWithCaption."Object Caption";
            end;
        }
        field(22; "Object Name"; Text[249])
        {
            Caption = 'Object Name';
            Editable = false;
        }
        field(23; "Allow View"; Boolean)
        {
            Caption = 'Allow View';
            InitValue = true;
            ToolTip = 'For a Table: grants Read. For a Page: grants the ability to open it (Execute).';
        }
        field(24; "Allow Insert"; Boolean)
        {
            Caption = 'Allow Create';
            ToolTip = 'Table only. Not applicable to Pages.';
        }
        field(25; "Allow Modify"; Boolean)
        {
            Caption = 'Allow Edit';
            ToolTip = 'Table only. Not applicable to Pages.';
        }
        field(26; "Allow Delete"; Boolean)
        {
            Caption = 'Allow Delete';
            ToolTip = 'Table only. Not applicable to Pages.';
        }
    }

    keys
    {
        key(PK; "Bundle Code", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        ValidateLineComplete();
    end;

    trigger OnModify()
    begin
        ValidateLineComplete();
    end;

    local procedure ValidateLineComplete()
    begin
        case "Line Type" of
            "Line Type"::"Permission Set":
                TestField("Permission Set ID");
            "Line Type"::"Object":
                begin
                    TestField("Object ID");
                    if ("Object Type" = "Object Type"::Page) and
                       ("Allow Insert" or "Allow Modify" or "Allow Delete")
                    then
                        Error('Insert/Modify/Delete don''t apply to a Page line. Use Allow View only, and add the underlying table as a separate line if it needs write access.');
                end;
        end;
    end;
}
