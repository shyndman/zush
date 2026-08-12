# This is a generated file by Linode-CLI! Do not modify!
_linode_cli()
{
local cur prev opts
COMPREPLY=()
cur="${COMP_WORDS[COMP_CWORD]}"
prev="${COMP_WORDS[COMP_CWORD-1]}"

case "${prev}" in
    linode-cli | linode | lin)
        COMPREPLY=( $(compgen -W "account betas child-account events payment-methods service-transfers users databases domains images image-sharegroups linodes kernels stackscripts lke resource-locks longview maintenance managed marketplace alerts monitor streams network-transfer firewalls networking vlans nodebalancers object-storage placement profile phone security-questions sshkeys regions tickets tags volumes vpcs --help" -- ${cur}) )
        return 0
        ;;
    account)
        COMPREPLY=( $(compgen -W "view update get-availability get-account-availability cancel invoices-list invoice-view invoice-items logins-list login-view maintenance-list notifications-list clients-list client-create client-view client-update client-delete client-reset-secret payments-list payment-create payment-view promo-add settings settings-update enable-managed transfer --help" -- ${cur}) )
        return 0
        ;;
        betas)
        COMPREPLY=( $(compgen -W "enrolled enroll enrolled-view list view --help" -- ${cur}) )
        return 0
        ;;
        child-account)
        COMPREPLY=( $(compgen -W "list view create --help" -- ${cur}) )
        return 0
        ;;
        events)
        COMPREPLY=( $(compgen -W "list view mark-seen --help" -- ${cur}) )
        return 0
        ;;
        payment-methods)
        COMPREPLY=( $(compgen -W "list add view delete default --help" -- ${cur}) )
        return 0
        ;;
        service-transfers)
        COMPREPLY=( $(compgen -W "list create view cancel accept --help" -- ${cur}) )
        return 0
        ;;
        users)
        COMPREPLY=( $(compgen -W "list create view update delete --help" -- ${cur}) )
        return 0
        ;;
        databases)
        COMPREPLY=( $(compgen -W "engines engine-view list mysql-config-view mysql-list mysql-create mysql-view mysql-update mysql-delete mysql-creds-view mysql-creds-reset mysql-patch mysql-resume mysql-ssl-cert mysql-suspend postgres-config-view postgresql-list postgresql-create postgresql-view postgresql-update postgresql-delete postgresql-conn-pool-list postgresql-conn-pool-create view postgresql-conn-pool-update postgresql-conn-pool-delete postgresql-creds-view postgresql-creds-reset postgresql-patch postgresql-resume postgresql-ssl-cert postgresql-suspend types type-view --help" -- ${cur}) )
        return 0
        ;;
        domains)
        COMPREPLY=( $(compgen -W "list create import view update delete clone records-list records-create records-view records-update records-delete zone-file --help" -- ${cur}) )
        return 0
        ;;
        images)
        COMPREPLY=( $(compgen -W "list create upload view update delete replicate sharegroups-list --help" -- ${cur}) )
        return 0
        ;;
        image-sharegroups)
        COMPREPLY=( $(compgen -W "list create tokens-list token-create token-view token-update token-delete view-by-token images-list-by-token view update delete images-list image-add image-update image-remove members-list member-add member-view member-update member-delete --help" -- ${cur}) )
        return 0
        ;;
        linodes)
        COMPREPLY=( $(compgen -W "list create view update delete backups-list snapshot backups-cancel backups-enable backup-view backup-restore boot clone configs-list config-create config-view config-update config-delete config-interfaces-list config-interface-add config-interfaces-order config-interface-view config-interface-update config-interface-delete disks-list disk-create disk-view disk-update disk-delete disk-clone disk-reset-password disk-resize firewalls-list firewalls-update post-apply-firewalls interfaces-list interface-add interface-history-list interfaces-settings-list interface-settings-update interface-view interface-update interface-delete interface-firewalls-list ips-list ip-add ip-view ip-update ip-delete migrate upgrade nodebalancers linode-reset-password reboot rebuild rescue resize shutdown transfer-view interfaces-upgrade volumes types type-view --help" -- ${cur}) )
        return 0
        ;;
        kernels)
        COMPREPLY=( $(compgen -W "list view --help" -- ${cur}) )
        return 0
        ;;
        stackscripts)
        COMPREPLY=( $(compgen -W "list create view update delete --help" -- ${cur}) )
        return 0
        ;;
        lke)
        COMPREPLY=( $(compgen -W "clusters-list cluster-create cluster-view cluster-update cluster-delete api-endpoints-list cluster-acl-view cluster-acl-update cluster-acl-delete cluster-dashboard-url kubeconfig-view kubeconfig-delete node-view node-delete node-recycle pools-list pool-create pool-view pool-update pool-delete pool-recycle cluster-nodes-recycle regenerate service-token-delete tiered-versions-list tiered-version-view types versions-list version-view --help" -- ${cur}) )
        return 0
        ;;
        resource-locks)
        COMPREPLY=( $(compgen -W "ls create view delete --help" -- ${cur}) )
        return 0
        ;;
        longview)
        COMPREPLY=( $(compgen -W "list create view update delete plan-view plan-update subscriptions-list subscription-view types --help" -- ${cur}) )
        return 0
        ;;
        maintenance)
        COMPREPLY=( $(compgen -W "policies-list --help" -- ${cur}) )
        return 0
        ;;
        managed)
        COMPREPLY=( $(compgen -W "contacts-list contact-create contact-view contact-update contact-delete credentials-list credential-create credential-sshkey-view credential-view credential-update credential-revoke credential-update-username-password issues-list issue-view linode-settings-list linode-setting-view linode-setting-update services-list service-create service-view service-update service-delete service-disable service-enable stats-list --help" -- ${cur}) )
        return 0
        ;;
        marketplace)
        COMPREPLY=( $(compgen -W "contacts-create --help" -- ${cur}) )
        return 0
        ;;
        alerts)
        COMPREPLY=( $(compgen -W "channels-list channels-create channels-view channels-update channels-delete channels-alerts-list definitions-list-all service-definitions-list definition-create definition-view definition-update definition-delete definition-entities-list --help" -- ${cur}) )
        return 0
        ;;
        monitor)
        COMPREPLY=( $(compgen -W "dashboards-list-all dashboards-view service-list service-view dashboards-list metrics-list token-get --help" -- ${cur}) )
        return 0
        ;;
        streams)
        COMPREPLY=( $(compgen -W "ls create destinations-list destination-create destination-view destination-update destination-delete destination-history-view view update delete history-view --help" -- ${cur}) )
        return 0
        ;;
        network-transfer)
        COMPREPLY=( $(compgen -W "prices --help" -- ${cur}) )
        return 0
        ;;
        firewalls)
        COMPREPLY=( $(compgen -W "list create firewall-settings-list firewall-settings-update templates-list template-view view update delete devices-list device-create device-view device-delete versions-list version-view rules-list rules-update --help" -- ${cur}) )
        return 0
        ;;
        networking)
        COMPREPLY=( $(compgen -W "ips-list ip-add ip-assign ip-share ip-view ip-update v6-pools v6-ranges v6-range-create v6-range-view v6-range-delete --help" -- ${cur}) )
        return 0
        ;;
        vlans)
        COMPREPLY=( $(compgen -W "list delete --help" -- ${cur}) )
        return 0
        ;;
        nodebalancers)
        COMPREPLY=( $(compgen -W "list create types view update delete configs-list config-create config-view config-update config-delete nodes-list node-create node-view node-update node-delete config-rebuild firewalls vpcs-list vpc-view --help" -- ${cur}) )
        return 0
        ;;
        object-storage)
        COMPREPLY=( $(compgen -W "ssl-view ssl-upload ssl-delete cancel clusters-list clusters-view endpoints global-quotas-list global-quota-view global-quota-usage-view keys-list keys-create keys-view keys-update keys-delete quotas-list quota-view quota-usage-view transfer-view types --help" -- ${cur}) )
        return 0
        ;;
        placement)
        COMPREPLY=( $(compgen -W "groups-list group-create group-view group-update group-delete assign-linode unassign-linode --help" -- ${cur}) )
        return 0
        ;;
        profile)
        COMPREPLY=( $(compgen -W "view update apps-list app-view app-delete devices-list device-view device-revoke logins-list login-view tfa-disable tfa-enable tfa-confirm tokens-list token-create token-view token-update token-delete --help" -- ${cur}) )
        return 0
        ;;
        phone)
        COMPREPLY=( $(compgen -W "sms-code-send delete verify --help" -- ${cur}) )
        return 0
        ;;
        security-questions)
        COMPREPLY=( $(compgen -W "list --help" -- ${cur}) )
        return 0
        ;;
        sshkeys)
        COMPREPLY=( $(compgen -W "list create view update delete --help" -- ${cur}) )
        return 0
        ;;
        regions)
        COMPREPLY=( $(compgen -W "list list-avail view view-avail --help" -- ${cur}) )
        return 0
        ;;
        tickets)
        COMPREPLY=( $(compgen -W "list create view close replies reply --help" -- ${cur}) )
        return 0
        ;;
        tags)
        COMPREPLY=( $(compgen -W "list create delete --help" -- ${cur}) )
        return 0
        ;;
        volumes)
        COMPREPLY=( $(compgen -W "list create types view update delete attach clone detach resize --help" -- ${cur}) )
        return 0
        ;;
        vpcs)
        COMPREPLY=( $(compgen -W "list create ips-all-list view update delete ips-list subnets-list subnet-create subnet-view subnet-update subnet-delete --help" -- ${cur}) )
        return 0
        ;;
    *)
        ;;
esac
}

complete -F _linode_cli linode-cli
complete -F _linode_cli linode
complete -F _linode_cli lin
