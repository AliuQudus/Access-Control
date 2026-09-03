page 70102 "User Access List"
{
    Caption = 'User Access Assignment';
    PageType = List;
    SourceTable = "User Access Header";
    CardPageId = "User Access Card";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
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
                }
                field("No. of Company Lines"; Rec."No. of Company Lines")
                {
                    ApplicationArea = All;
                    Caption = 'Companies Assigned';
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
                    Caption = 'Other Access Grants';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewUserAssignment)
            {
                Caption = 'New User Assignment';
                ApplicationArea = All;
                Image = NewUser;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Pick a user and create their access assignment.';

                trigger OnAction()
                var
                    SelectedUser: Record User;
                    UserAccessHeader: Record "User Access Header";
                begin
                    if Page.RunModal(Page::Users, SelectedUser) <> Action::LookupOK then
                        exit;

                    if UserAccessHeader.Get(SelectedUser."User Security ID") then begin
                        Message('%1 already has an access assignment. Opening it.', SelectedUser."User Name");
                        Page.Run(Page::"User Access Card", UserAccessHeader);
                        exit;
                    end;

                    UserAccessHeader.Init();
                    UserAccessHeader."User Security ID" := SelectedUser."User Security ID";
                    UserAccessHeader.Insert(true);
                    Page.Run(Page::"User Access Card", UserAccessHeader);
                    CurrPage.Update(false);
                end;
            }

            action(SyncAll)
            {
                Caption = 'Synchronize All Users';
                ApplicationArea = All;
                Image = RefreshLines;
                ToolTip = 'Apply every user''s current company/bundle assignment to the native Access Control table, and update their role center.';

                trigger OnAction()
                var
                    AccessSyncMgt: Codeunit "Access Sync Mgt.";
                begin
                    AccessSyncMgt.SyncAllUsers();
                    Message('Synchronization complete.');
                end;
            }
            action(CheckAllExternalAccess)
            {
                Caption = 'Check All for SUPER / Other Access';
                ApplicationArea = All;
                Image = SecurityFilter;
                ToolTip = 'Read-only scan: flags any user who has SUPER or other access from outside this tool. Does not change anything.';

                trigger OnAction()
                var
                    AccessSyncMgt: Codeunit "Access Sync Mgt.";
                    UserAccessHeader: Record "User Access Header";
                begin
                    if UserAccessHeader.FindSet() then
                        repeat
                            AccessSyncMgt.CheckExternalAccess(UserAccessHeader."User Security ID");
                        until UserAccessHeader.Next() = 0;
                    CurrPage.Update(false);
                    Message('Check complete. Users with SUPER or other external access are flagged above.');
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
