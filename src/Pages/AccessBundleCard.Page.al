page 70110 "Access Bundle Card"
{
    Caption = 'Access Group Card';
    PageType = Card;
    SourceTable = "Access Bundle";
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }
            part(Lines; "Access Bundle Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Bundle Code" = field(Code);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RebuildGeneratedPermissionSet)
            {
                Caption = 'Rebuild Generated Permission Set';
                ApplicationArea = All;
                Image = RefreshLines;
                ToolTip = 'Compiles this group''s Object-type lines (specific Pages/Tables) into their underlying permission set immediately, without waiting for a user to be synchronized. Permission-Set-type lines need no rebuild - they''re used as-is.';

                trigger OnAction()
                var
                    AccessSyncMgt: Codeunit "Access Sync Mgt.";
                begin
                    CurrPage.Update(true);
                    AccessSyncMgt.EnsureGroupPermissionSet(Rec.Code, Rec.Description);
                    Message('Rebuilt the generated permission set for %1.', Rec.Code);
                end;
            }
        }
    }
}
