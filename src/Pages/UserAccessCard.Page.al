page 70112 "User Access Card"
{
    Caption = 'User Access Card';
    PageType = Card;
    SourceTable = "User Access Header";
    ApplicationArea = All;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("User Security ID"; Rec."User Security ID")
                {
                    ApplicationArea = All;
                    Caption = 'User';
                    Editable = false;
                    ToolTip = 'Set once when the assignment is created. To change the user, delete this record and use "New User Assignment" again.';
                }
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = All;
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                }
                field("Default Role Center Profile ID"; Rec."Default Role Center Profile ID")
                {
                    ApplicationArea = All;
                    Caption = 'Role Center';
                }
                field("Last Synchronized On"; Rec."Last Synchronized On")
                {
                    ApplicationArea = All;
                }
                field("Has Super Permission"; Rec."Has Super Permission")
                {
                    ApplicationArea = All;
                    StyleExpr = SuperWarningStyle;
                }
                field("External Access Count"; Rec."External Access Count")
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "User Access Lines")
            {
                ApplicationArea = All;
                Caption = 'Companies and Access Bundles';
                SubPageLink = "User Security ID" = field("User Security ID");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Synchronize)
            {
                Caption = 'Synchronize Access';
                ApplicationArea = All;
                Image = RefreshLines;
                ToolTip = 'Apply this user''s current company/bundle assignment to the native Access Control table, and set their role center.';

                trigger OnAction()
                var
                    AccessSyncMgt: Codeunit "Access Sync Mgt.";
                begin
                    CurrPage.Update(true);
                    AccessSyncMgt.SyncUserAccess(Rec."User Security ID");
                    AccessSyncMgt.ApplyRoleCenter(
                        Rec."User Security ID", Rec."Default Role Center Profile ID", Rec."Default Role Center App ID");
                    CurrPage.Update(false);
                    Message('Access synchronized for %1.', Rec."Full Name");
                end;
            }
            action(CheckExternalAccess)
            {
                Caption = 'Check for SUPER / Other Access';
                ApplicationArea = All;
                Image = SecurityFilter;
                ToolTip = 'Read-only scan of this user''s native Access Control grants. Flags SUPER and counts anything not created by this tool. Does not change anything.';

                trigger OnAction()
                var
                    AccessSyncMgt: Codeunit "Access Sync Mgt.";
                begin
                    AccessSyncMgt.CheckExternalAccess(Rec."User Security ID");
                    CurrPage.Update(false);
                    if Rec."Has Super Permission" then
                        Message('%1 has SUPER from outside this tool. Assigned groups have no practical restricting effect until that''s addressed.', Rec."Full Name")
                    else
                        Message('No SUPER found. %1 other access grant(s) not created by this tool.', Rec."External Access Count");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Has Super Permission" then
            SuperWarningStyle := 'Attention'
        else
            SuperWarningStyle := 'Standard';
    end;

    var
        SuperWarningStyle: Text;
}
