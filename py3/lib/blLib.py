#!/unixworks/virtualenvs/py382/bin/python
blGroupType = { "Job":5005,
        "Smart_Job":5006,
        "Server":5003,
        "Smart_Server":5007,
        "Depot":5001,
        "Smart_Depot":5012,
        "Template":5008,
        "Smart_Template":5016,
        "Component":5014,
        "Smart_Component":5015,
        "System_Package":5025
}
blGroupTypeToNamespace = {
"Job":"JobGroup",
"Smart_Job":"SmartJobGroup",
"Server":"ServerGroup",
"Smart_Server":"SmartServerGroup",
"Depot":"DepotGroup",
"Smart_Depot":"SmartDepotGroup",
"Template":"TemplateGroup",
"Smart_Template":"SmartTemplateGroup",
"System_Package":"SystemPackageGroup"
}

#blJobType = [ 
#"NSH_SCRIPT_JOB",
#"BATCH_JOB",
#"FILE_DEPLOY_JOB",
#"DEPLOY_JOB",
#"ACL_PUSH_JOB",
#"AUDIT_JOB",
#"BLPACKAGE_BUILDER_JOB",
#"CLEANUP_JOB",
#"COMPLIANCE_JOB",
#"COMPONENT_DISCOVERY_JOB",
#"PATCH_ANALYSIS_JOB",
#"PROVISION_JOB",
#"SNAPSHOT_JOB",
#"UNINSTALL_JOB",
#"UPDATE_SERVER_PROPERTY_JOB",
#"WORKFLOW_JOB",
#"AGENT_INSTALLER_JOB"
#]
blJobType = [
"JOB",
"NSH_SCRIPT_JOB",
"PATCH_REMEDIATION_JOB",
"REDHAT_PATCHING_JOB",
"BATCH_JOB",
"DEPLOY_JOB",
"UNINSTALL_JOB",
"ACL_PUSH_JOB",
"PATCHING_JOB",
"WINDOWS_PATCHING_JOB",
"UPDATE_SERVER_PROPERTY_JOB",
"VIRTUAL_GUEST_JOB",
"AGENT_INSTALLER_JOB",
"FILE_DEPLOY_JOB",
"PATCH_ANALYSIS_JOB",
"SUPERJOB",
"AIX_PATCHING_JOB",
"AUDIT_JOB",
"SNAPSHOT_JOB",
"OTHER_LINUX_PATCHING_JOB",
"PULLJOB",
"CLEANUP_JOB",
"DOWNLOAD_JOB",
"BLPACKAGE_BUILDER_JOB",
"SYNC_JOB",
"DEPLOY_DRYRUN_JOB",
"DEPLOY_STAGING_JOB",
"DEPLOY_APPLY_JOB",
"DEPLOY_UNDO_JOB",
"PATCH_SUBSCRIPTION_JOB",
"REDHAT_PATCH_CATALOG_UPDATE_JOB",
"SOLARIS_PATCH_CATALOG_UPDATE_JOB",
"WINDOWS_PATCH_CATALOG_UPDATE_JOB",
"OTHER_LINUX_PATCH_CATALOG_UPDATE_JOB",
"AIX_PATCH_CATALOG_UPDATE_JOB",
"COMPONENT_DISCOVERY_JOB",
"PROVISION_JOB",
"UCS_PROVISION_JOB",
"COMPLIANCE_JOB",
"POLICY_UPGRADE_JOB",
"PCT_PUSH_JOB",
"VSM_DISCOVERY_JOB",
"AIX_PATCH_ANALYSIS_JOB",
"OTHER_LINUX_PATCH_ANALYSIS_JOB",
"WINDOWS_PATCH_ANALYSIS_JOB",
"SOLARIS_PATCH_ANALYSIS_JOB",
"REDHAT_PATCH_ANALYSIS_JOB",
"SOLARIS_PATCHING_JOB",
"PATCH_DOWNLOAD_JOB",
"WORKFLOW_JOB",
"PLUGIN_DISTRIBUTION_JOB",
"PLUGIN_DEREGISTRATION_JOB",
"ATRIUM_TO_BL_SYNC_JOB"
]
blGetDBKeyJobTypes = [
"NSHScriptJob",
"DeployJob",
"BatchJob",
"FileDeployJob",
"PatchRemediationJob",
"PatchingJob",
"ProvisionJob",
"AclPushJob",
"AuditJob",
"AgentInstallerJob",
"ComplianceJob",
"ComponentDiscoveryJob",
"DeregisterConfigurationObjectsJob",
"DistributeConfigurationObjectsJob",
"PublishProductCatalogJob",
"SnapshotJob",
"UpdateServerPropertyJob",
"UpgradeModelObjectsJob",
"VSMDiscoveryJob",
"WorkflowJob",
]
blDeleteJobJobTypes = [
"NSHScriptJob",
"DeployJob",
"BatchJob",
"PatchingJob",
"AuditJob",
"AgentInstallerJob",
"ComponentDiscoveryJob",
"PublishProductCatalogJob",
"VSMDiscoveryJob",
"WorkflowJob"
"Virtualization"
]
blJobTypeMap = { 
"JOB":9005,
"NSH_SCRIPT_JOB":111,
"BATCH_JOB":200,
"DEPLOY_JOB":30,
"UNINSTALL_JOB":33,
"PATCHING_JOB":7007,
"WINDOWS_PATCHING_JOB":7009,
"OTHER_LINUX_PATCHING_JOB":7011,
"AIX_PATCHING_JOB":7013,
"FILE_DEPLOY_JOB":40,
"PATCH_ANALYSIS_JOB":45,
"SUPERJOB":2,
"AUDIT_JOB":31,
"SNAPSHOT_JOB":32,
"PULLJOB":34,
"CLEANUP_JOB":35,
"DOWNLOAD_JOB":46,
"BLPACKAGE_BUILDER_JOB":113,
"SYNC_JOB":190,
"DEPLOY_DRYRUN_JOB":201,
"DEPLOY_STAGING_JOB":202,
"DEPLOY_APPLY_JOB":203,
"DEPLOY_UNDO_JOB":204,
"PATCH_SUBSCRIPTION_JOB":220,
"REDHAT_PATCH_CATALOG_UPDATE_JOB":229,
"SOLARIS_PATCH_CATALOG_UPDATE_JOB":232,
"WINDOWS_PATCH_CATALOG_UPDATE_JOB":235,
"OTHER_LINUX_PATCH_CATALOG_UPDATE_JOB":238,
"AIX_PATCH_CATALOG_UPDATE_JOB":241,
"COMPONENT_DISCOVERY_JOB":405,
"PROVISION_JOB":5029,
"UCS_PROVISION_JOB":50350,
"COMPLIANCE_JOB":5106,
"POLICY_UPGRADE_JOB":5150,
"PCT_PUSH_JOB":9000,
"VSM_DISCOVERY_JOB":5410,
"ACL_PUSH_JOB":1009,
"UPDATE_SERVER_PROPERTY_JOB":1017,
"AIX_PATCH_ANALYSIS_JOB":6999,
"OTHER_LINUX_PATCH_ANALYSIS_JOB":7000,
"WINDOWS_PATCH_ANALYSIS_JOB":7001,
"SOLARIS_PATCH_ANALYSIS_JOB":7002,
"REDHAT_PATCH_ANALYSIS_JOB":7003,
"REDHAT_PATCHING_JOB":7004,
"SOLARIS_PATCHING_JOB":7006,
"PATCH_DOWNLOAD_JOB":7030,
"PATCH_REMEDIATION_JOB":7032,
"WORKFLOW_JOB":9100,
"VIRTUAL_GUEST_JOB":50002,
"AGENT_INSTALLER_JOB":5850,
"PLUGIN_DISTRIBUTION_JOB":5170,
"PLUGIN_DEREGISTRATION_JOB":5180,
"ATRIUM_TO_BL_SYNC_JOB":5190 ,
}
## this is a special list of job types for the getDBKeyByGroupAndName function family
## it's intended to be in order of the most to least frequently used types
## this is based on a raw guess
#blJobKeyJobTypes {
#"NSHScriptJob",
#"DeployJob",
#"AclPushJob",
#"BatchJob",
#"FileDeployJob",
#"AuditJob",
#"AgentInstallerJob",
#"WorkflowJob",
#"ProvisionJob",
#"ComplianceJob",
#"UpdateServerPropertyJob",
#"ComponentDiscoveryJob",
#"PatchRemediationJob",
#"PatchingJob",
#"PublishProductCatalogJob",
#"SnapshotJob",
#"UpgradeModelObjectsJob",
#"DeregisterConfigurationObjectsJob",
#"DistributeConfigurationObjectsJob",
#"VSMDiscoveryJob"
#}
blDepotObjectTypeShort = { 
"DEPOT_FILE_OBJECT":73, # file
"NSHSCRIPT":1, # NshScript
"BLPACKAGE":28, # BlPackage
}
blDepotObjectTypeComplete = {
"ACL_PUSH_JOB" : 1009 ,
"AIX_PACKAGE_INSTALLABLE" : 84 ,
"AIX_PATCH_INSTALLABLE" : 83 ,
"AGENT_INSTALLER_JOB" : 5850,
"AUDIT_JOB" : 31 ,
"BATCH_JOB" : 200 ,
"BLPACKAGE" : 28 ,
"COMPLIANCE_JOB" : 5106 ,
"COMPONENT_DISCOVERY_JOB" : 405 ,
"CUSTOM_SOFTWARE_INSTALLABLE" : 95 ,
"DEPLOY_JOB" : 30 ,
"DEPOT_FILE_OBJECT" : 74 ,
"FILE_DEPLOY_JOB" : 40 ,
"HOTFIX_WINDOWS_INSTALLABLE" : 114 ,
"HP_BUNDLE_INSTALLABLE" : 103 ,
"HP_PATCH_INSTALLABLE" : 104 ,
"HP_PRODUCT_INSTALLABLE" : 71 ,
"IIS_HOTFIX_WINDOWS_INSTALLABLE" : 115 ,
"INSTALLSHIELD_WINDOWS_INSTALLABLE" : 119 ,
"MSI_WINDOWS_INSTALLABLE" : 118 ,
"NSHSCRIPT" : 1 ,
"NSH_SCRIPT_JOB" : 111 ,
"PATCH_ANALYSIS_JOB" : 45 ,
"RPM_INSTALLABLE" : 68 ,
"SERVICEPACK_WINDOWS_INSTALLABLE" : 117 ,
"SNAPSHOT_JOB" : 32 ,
"SOLARIS_PACKAGE_INSTALLABLE" : 67 ,
"SOLARIS_PATCH_CLUSTER_INSTALLABLE" : 88 ,
"SOLARIS_PATCH_INSTALLABLE" : 69 ,
"TEMPLATE" : 250 ,
"UPDATE_SERVER_PROPERTY_JOB" : 1017
}

#blGroupType = {
#"DEPOT_GROUP" : 5001,
#"STATIC_SERVER_GROUP" : 5003,
#"SERVER" : 5004,
#"JOB_GROUP" : 5005,
#"SMART_JOB_GROUP" : 5006,
#"SMART_SERVER_GROUP" : 5007,
#"TEMPLATE_GROUP" : 5008,
#"COMPONENT_TEMPLATE_GROUP" : 5009,
#"MSPATCH_MODEL_GROUP" : 5010,
#"SMART_DEPOT_GROUP" : 5012,
#"STATIC_COMPONENT_GROUP" : 5014,
#"SMART_COMPONENT_GROUP" : 5015,
#"SMART_TEMPLATE_GROUP" : 5016,
#"SMART_WINDOWS_PATCH_CATALOG_GROUP" : 5017,
#"SMART_REDHAT_PATCH_CATALOG_GROUP" : 5018,
#"SMART_SOLARIS_PATCH_CATALOG_GROUP" : 5019,
#"RED_HAT_CATALOG_GROUP" : 5020,
#"SOLARIS_CATALOG_GROUP" : 5021,
#"WINDOWS_CATALOG_GROUP" : 5022,
#"SMART_AIX_PATCH_CATALOG_GROUP" : 5046,
#"SMART_OTHER_LINUX_PATCH_CATALOG_GROUP" : 5024,
#"SYSTEM_PACKAGE_GROUP" : 5025,
#"OS_COMPONENT_GROUP" : 5027,
#"SMART_PM_DEVICE_GROUP" : 5044,
#"COMPLIANCE_RULE_GROUP" : 5205,
#"SMART_PM_DEVICE_GROUP" : 5044,
#"OTHER_LINUX_CATALOG_GROUP" : 7035,
#"AIX_CATALOG_GROUP" : 7037
#}

def file_as_normalized_list(fname):
    return [x.strip().lower() for x in open(fname,mode="rt").readlines()]    