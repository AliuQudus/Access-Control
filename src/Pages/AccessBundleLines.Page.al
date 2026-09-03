page 70101 "Access Bundle Lines"
{
    Caption = 'Group Contents';
    PageType = ListPart;
    SourceTable = "Access Bundle Line";
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = All;
                }

                field(Scope; Rec.Scope)
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" = Rec."Line Type"::"Permission Set";
                    Visible = true;
                }
                field("Permission Set ID"; Rec."Permission Set ID")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" = Rec."Line Type"::"Permission Set";
                }
                field("Permission Set Name"; Rec."Permission Set Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" = Rec."Line Type"::"Object";
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" = Rec."Line Type"::"Object";
                    ToolTip = 'Look up the Table or Page by its ID. If you pick a Page, also add its underlying table(s) as separate lines with the write access it needs.';
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Allow View"; Rec."Allow View")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" = Rec."Line Type"::"Object";
                }
                field("Allow Insert"; Rec."Allow Insert")
                {
                    ApplicationArea = All;
                    Editable = (Rec."Line Type" = Rec."Line Type"::"Object") and (Rec."Object Type" = Rec."Object Type"::Table);
                }
                field("Allow Modify"; Rec."Allow Modify")
                {
                    ApplicationArea = All;
                    Editable = (Rec."Line Type" = Rec."Line Type"::"Object") and (Rec."Object Type" = Rec."Object Type"::Table);
                }
                field("Allow Delete"; Rec."Allow Delete")
                {
                    ApplicationArea = All;
                    Editable = (Rec."Line Type" = Rec."Line Type"::"Object") and (Rec."Object Type" = Rec."Object Type"::Table);
                }
            }
        }
    }
}
