page 70103 "User Access Lines"
{
    Caption = 'Company / Access Group Assignments';
    PageType = ListPart;
    SourceTable = "User Access Line";
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Leave blank to grant this bundle across all companies.';
                }
                field("Bundle Code"; Rec."Bundle Code")
                {
                    ApplicationArea = All;
                }
                field("Bundle Description"; Rec."Bundle Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
}
