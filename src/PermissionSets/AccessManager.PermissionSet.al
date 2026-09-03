permissionset 70100 "ACCESS MGR ADMIN"
{
    Caption = 'Access Manager - Admin';
    Assignable = true;
    Access = Public;

    Permissions =
        tabledata "Access Bundle" = RIMD,
        tabledata "Access Bundle Line" = RIMD,
        tabledata "User Access Header" = RIMD,
        tabledata "User Access Line" = RIMD,
        tabledata "Managed Access Entry" = RIMD,
        tabledata "Tenant Permission Set" = RIMD,
        tabledata "Tenant Permission" = RIMD,
        tabledata User = R,
        table "Access Bundle" = X,
        table "Access Bundle Line" = X,
        table "User Access Header" = X,
        table "User Access Line" = X,
        table "Managed Access Entry" = X,
        page "Access Bundles" = X,
        page "Access Bundle Card" = X,
        page "Access Bundle Lines" = X,
        page "User Access List" = X,
        page "User Access Card" = X,
        page "User Access Lines" = X,
        page "Effective Access Overview" = X,
        codeunit "Access Sync Mgt." = X;
}
