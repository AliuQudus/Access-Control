table 70100 "Access Bundle"
{
    Caption = 'Access Group';
    DataClassification = CustomerContent;
    LookupPageId = "Access Bundles";
    DrillDownPageId = "Access Bundles";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Comment; Text[250])
        {
            Caption = 'Notes';
        }
        field(4; "No. of Permission Sets"; Integer)
        {
            Caption = 'No. of Permission Sets';
            FieldClass = FlowField;
            CalcFormula = count("Access Bundle Line" where("Bundle Code" = field(Code)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
