page 70100 "Access Bundles"
{
    Caption = 'Access Groups';
    PageType = List;
    SourceTable = "Access Bundle";
    CardPageId = "Access Bundle Card";
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("No. of Permission Sets"; Rec."No. of Permission Sets")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
