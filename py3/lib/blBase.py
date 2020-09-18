#!/unixworks/virtualenvs/py382/bin/python
# Version: 1.1 Mar 23, 2016
# Adding better error handling to detect login error.
# Version "a bunch": added a bunch of stuff
# 2019-07-18 - add serverGroupDBKey
# 2019-08-26 - make the but that chmods the log dir work
import zeep
from zeep import Client
from zeep.plugins import HistoryPlugin
import os, socket
import re
import time
import sys
import datetime
import logging
import traceback as tb
import configparser
import blLib
import stat
import json
import socket
#import pymssql
import requests
import pytz, datetime
sys.path.append('../')
# from tests import *
#from suds import WebFault
#import suds
from requests import Session
#from suds.client import Client
#from suds.transport.http import HttpAuthenticated
#from suds.xsd.sxbasic import Import
from getpass import getpass
import base64
import io
from subprocess import check_output, PIPE
from shutil import rmtree
from fcntl import flock, LOCK_UN, LOCK_EX
from os.path import isdir
import inspect
from inspect import currentframe, getframeinfo

settingsFile="/unixworks/bl_tools/etc/settings.json"

class blBase:
    sessionId=None
    loginUrl=None
    roleUrl=None
    baseRoleUrl=None
    blPassType=None
    blUser=None
    blPass=None
    blRole=None
    blConf=None
    ## user config
    blConfFile=None
    blIP=None
    debug=None
    myGroup=None
    defaultMyGroup=None
    serverGroup=None
    serverMap=None
    serverMapCsv="/unixworks/bl_tools/bldata/US-ServerMapping.csv"
    UIfile="/unixworks/bl_tools/etc/UI.json"
    ## global settings
    UIbackends=None
    suds_lock=None
    loginattempts=0
    ipdbfile=None
    ipdblockfile=None
    devhosts=None
    prodhosts=None
    rbCursor=None
    Session=None
    Transport=None
    loginResult=None
    loginClient=None
    roleClient=None
    blCliClient=None
    frontHost=None
    proxyHost=None
    serviceUrls=None
    initClientsStartTime = None
    initClientsEndTime = None
    logbase="/tmp/bl_tools_log"
    ## set from settingsFile
    bladelogicticketurl = None
    unsupported_text = " -- UNSUPPORTED - uses unpublished bladelogic API."
    trynum = 1
    #fname = lambda: inspect.stack()[1][3]

    @staticmethod
    def fname():
        return inspect.stack()[1][3]

    @staticmethod
    def f_loc():
        frameinfo = getframeinfo(currentframe().f_back)
        return frameinfo.filename + ":" + frameinfo.function + ":" + str(frameinfo.lineno)

    @staticmethod
    def setUnsupported(parser):
        if sys.argv[0].split(".")[-1] == "u":
            parser.set_usage(parser.get_usage().strip() + blBase.unsupported_text)

    @staticmethod
    def getMyGroup(): 
        if "myGroup" in os.environ:
            return os.environ["myGroup"]
        else:
            print("environment variable myGroup is not set.  please run bl_conf")
            sys.exit(1)

    @staticmethod
    def getMyCfg():
        return str(blBase.getMyHome()) + "/" + ".bl_tools/conf/" + str(blBase.getMyConf())

    @staticmethod
    def getMyConf():
        if "BL_CONF" in os.environ:
            return os.environ["BL_CONF"]
        else:
            print("environment variable BL_CONF is not set.  please run bl_conf")
            sys.exit(1)

    @staticmethod
    def getMyUser():
        cfg = blBase.getMyCfg()
        conf = configparser.RawConfigParser()
        conf.read(cfg)
        return conf.get('Bladelogic', 'blUser')

    @staticmethod
    def getMyRole():
        cfg = blBase.getMyCfg()
        conf = configparser.RawConfigParser()
        conf.read(cfg)
        return conf.get('Bladelogic', 'blRole')

    @staticmethod
    def getMyServerGroup(): 
        cfg = blBase.getMyCfg()
        conf = configparser.RawConfigParser()
        conf.read(cfg)
        return conf.get('Bladelogic', 'serverGroup')

    def initServerMap(self):
        role = blBase.getMyRole()
        if self.debug: print("getting serverMap from ",self.serverMapCsv)
        servermap = open(self.serverMapCsv, mode="rt")
        serverlist = [x.split(',')[0] for x in servermap.readlines() if re.search(":" + role + ":", x)]
        self.serverMap = dict([ (x.split(".")[0].lower(),x) for x in serverlist])
        
        grp = blBase.getMyServerGroup()
        if self.debug: print("updating serverMap from \"" + grp + "\"")
        ##print inspect.getframeinfo(inspect.currentframe()).function,": servergroup",grp
        result = self.runBlcli("Server","listServersInGroup",[grp])
        if result.success:
            #print result
            #serverlist = result.returnValue.split("\n")[:-1]
            serverlist = result.returnValue.strip().split("\n")
            #print "which has",len(serverlist),"entries."
            #print "The first one by alphabetical order is",sorted(serverlist)[0] + ". ", "The last one by alphabetical order is is",sorted(serverlist)[-1] + "."
            self.serverMap.update(dict([ (x.split(".")[0].lower(), x) for x in serverlist]))
    #    print "leaving initServerGroupMap()"

    @staticmethod
    def getMyHome():
        from pwd import getpwnam
        if "USER" in os.environ:
            user=os.environ["USER"]
        elif "PBUSER" in os.environ:
            user=os.environ["PBUSER"]
        else:
            raise Exception("couldn't determine user - this is needed to get the user config file")
        return getpwnam(user).pw_dir

    @staticmethod
    def normalizeArg(pathedArg,argname):
        ## remove trailing slashes
        if len(pathedArg)>1 and re.search("/$",pathedArg):
            pathedArg = pathedArg[0:-1]
        myGroup = blBase.getMyGroup()
        if re.search("^/",pathedArg):
            group="/".join(pathedArg.split("/")[:-1])
            file=pathedArg.split("/")[-1]
            return [group,file]
        # strip off leading ./
        if myGroup and re.match("^./",pathedArg):
            print("pathedArg=",pathedArg,"which changes to",pathedArg[2:])
            pathedArg=pathedArg[2:]
        if myGroup and not re.search("^/",pathedArg):
            pathedArg = myGroup + "/" + pathedArg
            group="/".join(pathedArg.split("/")[:-1])
            file=pathedArg.split("/")[-1]
            return [group,file]
        else:
            print("pathedArg",pathedArg,"argname",argname)
            raise Exception("If $myGroup is not defined, arg must start with '/'.  This applies to",argname)


    def writeFooter():
        print("</body>")
        print("</html>")

    def writeHeader():
        print("Content-type:text/html\r\n\r\n")
        print("<html>")
        print("<head>")
        print("<title>Server Enrollment Status</title>")
        print("</head>")
        print("<body>")

    def BlLogin(self, client, uName, uPass, passType):
    #    try:
            if self.debug: print(self.loginUrl)
            if self.debug: print("logging in with",uName,uPass,passType)
            result = self.loginClient.service.loginUsingUserCredential(uName,uPass,passType)
            return result
#        except Exception, e:
#            print "ERROR: Could not login to BladeLogic</p>"
#            print "Exception:",e
#            sys.exit(1)


    def runBlcli(self, nameSpace, subCommand, Arguments):
        if self.debug: print(self.cliUrl, self.sessionId, nameSpace, subCommand, Arguments)
        try:
            return self.blCliClient.service.executeCommandByParamList(nameSpace, subCommand, Arguments)
        except Exception as e:
            print("Exception:runBlcli(",str(nameSpace) + ","+str(subCommand)+","+str(Arguments)+"):",e)
            sys.exit(1)

    ## this is currently not used in any live code, but may be useful
    ## It will probably be requred that suds.null() be replaced with something else but who knows
    def runBlcli2(self, nameSpace, subCommand, Arguments):
        if self.debug: print(self.cliUrl, self.sessionId, nameSpace, subCommand, Arguments)
        try:
            return self.blCliClient2.service.executeCommandByParamListAndAttachment(nameSpace, subCommand, Arguments,zeep.helpers.Nil())
        except Exception as e:
            print("Exception:runBlcli2(",str(nameSpace) + ","+str(subCommand)+","+str(Arguments)+"):")
            print(e)
            sys.exit(1)

    def mkdir_recursive(self,grouptype,completed,remaining):
        ''' mkdir_recursive(grouptype,completed,remaining) -> True or False
            grouptype must be "DepotGroup","JobGroup", or "StaticServerGroup"
            Typically should be callsed with completed == "" and remaining being a fully qualified path
            Otherwise, remaining should have no prepended / or ./
            completed and remaining should have no trailing slashes
            Example:
            mkdir_recursive("JobGroup","","/fully/qualified/path")
            mkdir_recursive("JobGroup",bl.myGroup,"stuff/you/want/to/create/in/home")
            mkdir_recursive("JobGroup","",bl.myGroup + "/" + "stuff/you/want/to/create/in/home")
        '''
        #print "mkdir_recursive(",grouptype,completed,remaining,")"

        ## convert double slashes to single slashes
        remaining = re.sub("\/+","/", remaining)
        completed = re.sub("\/+","/", completed)
        ## preserve this for sanity check at the end
        origRemaining = remaining
        origCompleted = completed
        ## check if input is valid
        if not grouptype in set(["JobGroup","DepotGroup","StaticServerGroup"]):
            raise Exception("group type mustbe one of JobGroup, DepotGroup, StaticServerGroup")

        ## check for valid paths
        if (completed == "" and re.match("^(/[^/]+)+$",remaining)) or \
            (re.match("^(/[^/]+)+$",completed) and remaining == "") or \
            (re.match("^(/[^/]+)+$",completed) and re.match("^[^/]+(/[^/]+)*$",remaining)):
            # keep going
            pass;
        else:   raise Exception("mkdir_recursive("+grouptype+"," + repr(completed)+","+repr(remaining)+") is not a valid call")
        #print "passed the sanity checks with",grouptype,completed,remaining

        while remaining:
            #print "function input looks sane, going ahead with completed =",repr(completed),"remaining = ",repr(remaining)
            if completed == "":
                remaining = remaining[1:]
            completed = completed + "/" + remaining.split("/")[0]
            remaining = "/".join(remaining.split("/")[1:])
            result = self.runBlcli(grouptype,"groupExists",[completed])
            if not result.success:
                raise Exception(str(blBase.f_loc()+": lookup of "+grouptype+" "+completed+" was problematic: "+str(result)))
            else:
                if result.returnValue == "true":
        #            print "found",grouptype,completed
                    continue
                else:
        #            print "creating",grouptype,completed + ":",
                    (parentGroup,childGroup) = blBase.normalizeArg(completed,"in mkdir_recursive")
                    print("self.runBlcli(",grouptype,"createGroupWithParentName",[childGroup,parentGroup], end=' ')
                    result = self.runBlcli(grouptype,"createGroupWithParentName",[childGroup,parentGroup])
                    print(result.success)
                    if not result.success:
                        raise Exception(str("creation of"),grouptype,completed,"was problematic: "+str(result))
                    else:
                        continue
        # final verification
        fullpath = origCompleted + "/" + origRemaining
        result = self.runBlcli(grouptype,"groupExists",fullpath)
        if not result.success:
            raise Exception(str("lookup of",grouptype,fullpath,"was problematic:",str(result)))
        elif result.returnValue == "true": 
            return True
        elif result.returnValue == "false": 
            return False

    def getFQJobGroupByJobDBKey(self,dbkey):
        result = self.runBlcli("Job","getGroupId",[dbkey])
        if not result.success:
            return result
        else:
            if self.debug: print(blBase.fname(),": result:",result)
            return self.getFQGroupByID(result.returnValue)
#
    def getFQGroupByID(self,id):
        for jobtype in blLib.blGroupType:
            result = self.runBlcli("Group","getAQualifiedGroupName",[blLib.blGroupType[jobtype],id])
            if result.success:
                if self.debug: print(fname(),": getFQGroupByID:",str(result))
                return result
        return result

    def getGroupID(self,groupType,grPath):
        """release command for 5.8"""
        namespace = blLib.blGroupTypeToNamespace[groupType]
        return self.runBlcli(namespace,"groupNameToId",[grPath])

    def getGroupDBKey(self,groupType,groupName):
        namespace = blLib.blGroupTypeToNamespace[groupType]
        return self.runBlcli(namespace,"groupNameToDBKey",[groupName])

    #def listFileGroup(self,groupType,grPath):
    #    grID = self.getGroupID(groupType,grPath)
    #    if not grID.success:
    #        return None
    #    print grID

    def listGroup(self,groupType,grPath):
        grID = self.getGroupID(groupType,grPath)
        if not grID.success:
            return None
        grType = blLib.blGroupType[groupType]
        #result = self.runBlcli("DepotObject","listAllByGroup",[grPath])
        #print "Group","findAllByParentGroup",[grType,grID]
        result = self.runBlcli("Group","findAllByParentGroup",[grType,grID])
        return result

    def listGroupFolders(self,groupType,grPath):
        grID = self.getGroupID(groupType,grPath)
        if not grID.success:
            return None
        grType = blLib.blGroupType[groupType]
        #result = self.runBlcli("DepotObject","listAllByGroup",[grPath])
        result = None
        if groupType == "Depot":
            result = self.runBlcli("DepotGroup","findAllByParentGroup",[grID])
        elif groupType == "Job":
            result = self.runBlcli("JobGroup","findAllByParentGroup",[grID])
        print(result)
        result = self.runBlcli("Group","findAllByParentGroup",[grType,grID])
        print(result)
        return result

    def listGroupFiles(self,groupType,grPath):
        """These are all release commands in 5.8"""
        grID = self.getGroupID(groupType,grPath)
        if grID is None:
            return None
        grType = blLib.blGroupType[groupType]
        result = None
        if groupType == "Depot":
            result = self.runBlcli("DepotObject","listAllByGroup",[grPath])
        if groupType == "Job":
            result = self.runBlcli("Job","listAllByGroup",[grPath])
        if groupType == "Server":
            result = self.runBlcli("Server","listServersInGroup",[grPath])

        return result

    def listFile(self,groupType,filePath):
        grPath = "/".join(filePath.split("/")[:-1])
        grID = self.getGroupID(groupType,grPath)
        print("GroupID,DBKey,File")
        print(grID, end=' ')

    # this doesn't work on jobgroups.  also, modelTypeTOID is not published
    #def fileDBKey(self,groupType,filePath):
    #    grPath = "/".join(filePath.split("/")[:-1])
    #    fileName = filePath.split("/")[-1]
    #    if groupType=="Job":
    #        for jobtype in blLib.blJobType:
    #            result = self.runBlcli("Job","getDBKeyByTypeGroupAndName",[grPath,fileName,self.modelTypeToID(jobtype).returnValue])
    #            #result = self.runBlcli("Job","getDBKeyByTypeStringGroupAndName",[jobtype,grPath,fileName])
    #            if result.success:
    #                return result
    #    if groupType=="Depot":
    #        for dtype in blLib.blDepotObjectTypeShort.keys():
    #            result = self.runBlcli("DepotObject","getDBKeyByTypeStringGroupAndName",[dtype,grPath,fileName])
    #            if result.success:
    #                return result

    def depotObjectDBKey(self,groupName,fileName):
        for filetype in list(blLib.blDepotObjectTypeShort.keys()):
            result = self.runBlcli("DepotObject","getDBKeyByTypeStringGroupAndName",[filetype,groupName,fileName])
            if result.success: return result

    def depotGroupDBKey(self,groupName):
        result = self.runBlcli("DepotGroup","groupNameToDBKey",[groupName])
        if result.success: return result

    def serverGroupDBKey(self,groupName):
        result = self.runBlcli("ServerGroup","groupNameToDBKey",[groupName])
        if result.success: return result

    def serverDBKey(self,fqdn):
                result = self.runBlcli("Server","getServerDBKeyByName",[fqdn])
                #if result.success: return result # "".join(result.returnValue.split("-")[0].split("Model"))
                if result.success: 
                    result.returnValue = "".join(result.returnValue.split("-")[0].split("Model"))
                    return result

    def jobGroupDBKey(self,groupName):
        print("JobGroup",groupName,": trying to find dbkey:", end=' ')
        result = self.runBlcli("JobGroup","groupNameToDBKey",[groupName])
        if result.success: 
            print(result.returnValue)
            return result
    #def depotDBKey(self,groupName):
    #    parent = "/".join(groupName.split("/")[:-1])
    #    child = groupName.split("/")[-1]
    #    return self.runBlcli("DepotObject","getDBKeyByTypeStringGroupAndName",["DEPOT_GROUP",parent,child])

    def NSHScriptJobDBKey(self,jobGroup,jobName):
        return  self.runBlcli("NSHScriptJob","getDBKeyByGroupAndName",[jobGroup,jobName])

    def BatchJobDBKey(self,jobGroup,jobName):
        return  self.runBlcli("BatchJob","getDBKeyByGroupAndName",[jobGroup,jobName])

    def jobDBKey(self,jobGroup,jobName):
        result=None
        for jobtype in blLib.blGetDBKeyJobTypes:
            #yif self.debug: print jobGroup,jobName,": trying",jobtype,"to find dbkey:",
            print(jobGroup,jobName,": trying",jobtype,"to find dbkey:", end=' ')
            #jobtypeid=self.modelTypeToID(jobtype)
            result = self.runBlcli(jobtype,"getDBKeyByGroupAndName",[jobGroup,jobName])
            if result.success:
                print(result.returnValue)
                return result
            print(False)
        return result

    def jobTargets(self,jobGroup,jobName):
        result = self.runBlcli("NSHScriptJob","findJobKeyByGroupAndName",[jobGroup,jobName])
        if result.success: jobdbkey=result.returnValue
        else: return result
        #print self.runBlcli("NSHScriptJob","getNSHScriptParamValues",[jobdbkey])
        #targetresult = self.runBlcli("Job","getTargets",[jobdbkey,"Servers"])
        targetresult = self.runBlcli("Job","getTargets",[jobdbkey,"Servers"])
        if targetresult.success: return targetresult.returnValues[1:-1].split(", ")
        else: return targetresult

    #job.getGroupId(dbkey)->groupid
    #job.getJobNameByDBKey(dbkey)->name
    #JobGroup.groupNameToID(groupname)->groupid
    # file:///C:/Users/USERID/Documents/GROUP/BladeLogic/doc/BlFile.html#setFileCopyLocation-DEFAULT-11083 -> file permissions and ownerships.
    # for this one, we need the "set current object" function: Utility.setTargetObject
        # In FileTransfer, be aware of: copySvrToSvr, delete, moveSvrToSvr, pullResultsFileFromAppServer, pushFileToAppServer

    def modelTypeToID(self,modeltype):
        return self.runBlcli("Utility","convertModelType",[modeltype])

    def validateServerList(self,serverlist,get_dbkey=False,verbose=False): # returns a dict with lists of "good" and "bad" servers, good mapped to fqdn used by bladelogic
        import concurrent.futures
        import time
        #t0 = time.time()
        #self.fileServerMap()
        goodservers=list()
        badservers=list()
        servermap=dict()
        servermap["good"]=goodservers
        servermap["bad"]=badservers
        servermap["dbkeys"]=dict()

        def validateServer(server,verbose=False):
            ## change to require fqdn rather than short name
            #server = server.split(".")[0].lower()
            server = server.lower()
            fqdn = server #self.blFQDN(server)

            if verbose:
                print("checking",server)
            #print server,self.serverMap.has_key(server)
            #if self.serverMap.has_key(server):
            #    fqdn = self.serverMap[server]
            if fqdn in self.serverMap.values():
                if get_dbkey:
                    result = self.runBlcli("Server","getServerDBKeyByName",[fqdn])
                    if result.success:
                        print(result.returnValue)
                        serverkey="".join(result.returnValue.split("-")[0].split("Model"))
                        servermap["dbkeys"][fqdn]=serverkey
                        goodservers.append(fqdn)
                    else:
                        print(server,"not validating server. dbkey was not found.")
                        badservers.append(server)
                else:
                    goodservers.append(fqdn)
            else:
                badservers.append(server)
                    
        for s in serverlist: validateServer(s,verbose)

        return servermap

    def copyJob(self,sourceGroup,sourceFile,dstGroup,dstFile):
        ## we can get this for batch job too.
#        dbkeyresult = self.NSHScriptJobDBKey(sourceGroup,sourceFile) 
        dbkeyresult = self.jobDBKey(sourceGroup,sourceFile) 
        if dbkeyresult.success:
            return self.runBlcli("Job","copyJob",[dbkeyresult.returnValue,dstGroup,dstFile])
        else: return dbkeyresult

        # if we need to expand outside of nshscript job and jobDBKey stops working, try this
        #from blLib import blJobType
        #for jobType in blJobType:
        #	result = self.runBlcli("Job","copyJob_1",[jobType,sourceGroup,sourceFile,dstGroup,dstFile])
        #	if result.success:
        #		return result
        #return result

#    def copyFile(self,sourceHost,sourcePath,destHost,destPath,verbose=False):
#        if verbose: print "getting",sourcePath,"from",sourceHost
#        result = self.runBlCli("File","getFileDataFromAgent",[sourceHost,sourcePath,"null"])
#        if result.success:
#            if verbose: print "putty to", destPath,"on",destHost
#            result = self.runBlCli("File","saveFileDataToAgent",[destHost,destPath,"null"])
#            return result.success
#        else: return result

    def catFile(self,sourceHost,sourcePath,verbose=False):
        """based on unsupported call to File getFileByteDataFromAgent"""

        if verbose: print("getting",sourcePath,"from",sourceHost)
        result = self.runBlcli("File","getFileByteDataFromAgent",[sourceHost,sourcePath,"null"])

        return result

    # this is deprecated as its possible to give a wrong answer if the shortname is not unique
    def localBlFQDN(self):
        #print "start localBlFQDN"
        import platform
        hostname=platform.node()
        #print "hostname",hostname
        hostname=hostname.split(".")[0].lower()
        #print "hostname",hostname
        fqdn = self.serverMap[hostname]
        #print "fqdn",fqdn
        #print "done localBlFQDN"
        return fqdn

    def addServersToJob(self,jobgroup,jobname,servers):
        """addServersToJob(jobkey,servers[])->result -- you should preverify the servers list is good"""
        #result = self.NSHScriptJobDBKey(jobgroup,jobname)
        result = self.jobDBKey(jobgroup,jobname)
        if not result.success:
            print("Couldn't find job key for",jobgroup + "/" + jobname)
            return result
        jobkey = result.returnValue
        servermap = self.validateServerList(servers)
        return self.runBlcli("Job","addTargetServers",[jobkey,",".join(servermap["good"])])

    def delServerFromJob(self,jobgroup,jobname,server):
        """addServersToJob(jobkey,server)->resultobj"""
        #result = self.NSHScriptJobDBKey(jobgroup,jobname)
        result = self.jobDBKey(jobgroup,jobname)
        if not result.success:
            print("Couldn't find job key for",jobgroup + "/" + jobname)
            return result
        jobkey = result.returnValue
        servermap = self.validateServerList([server])
        if servermap["good"]: server = servermap["good"][0]
        else: server = ""
        return self.runBlcli("Job","clearTargetServer",[jobkey,server])

    def addServerGroupsToJob(self,jobGroup,jobName,serverGroups):
        """addServerGroupsToJob(jobGroup,jobName,groups[])->resultobj"""
        #result = self.NSHScriptJobDBKey(jobGroup,jobName)
        result = self.jobDBKey(jobGroup,jobName)
        if not result.success:
            print("couldn't find jobkey for",jobGroup + "/" + jobName)
            return result
        else:
            jobkey = result.returnValue
        result = self.runBlcli("Job","addTargetGroups",[jobkey,",".join(serverGroups)])
        return result

    def delServerGroupFromJob(self,jobGroup,jobName,serverGroup):
        """delServerGroupsFromJob(jobGroup,jobName,groups[])->resultobj"""
        #result = self.NSHScriptJobDBKey(jobGroup,jobName)
        result = self.jobDBKey(jobGroup,jobName)
        if not result.success:
            print("couldn't find jobkey for",jobGroup + "/" + jobName)
            return result
        else:
            jobkey = result.returnValue
        return self.runBlcli("Job","clearTargetGroup",[jobkey,serverGroup])

    def serverGroupMembers(self,serverGroup):
        return self.runBlcli("Server","listServersInGroup",[serverGroup])

    @staticmethod
    def updateURLFQDN(url,fqdn):
        """update the url with a new fqdn/ip"""

        tmpurl=url.split("/")
        urlfqdn=tmpurl[2].split(":")
        urlfqdn[0]=fqdn
        tmpurl[2]=":".join(urlfqdn)
        return "/".join(tmpurl)

    def initLogging(self):
        user = blBase.getMyUser()
        user = user.replace("@",".")

        filename = self.logbase + "/" + user + "." + str(os.getuid()) + "." + str(time.time())

        if not os.path.isdir(self.logbase): os.mkdir(self.logbase)

        try: os.chmod(self.logbase,stat.S_IRWXO|stat.S_IRWXU|stat.S_IRWXG)
        except Exception as e: 
            print("WARNING:",self.logbase,"does not have 777 permissions.  Please fix this, or it could cause problems for other users.")
            print("WARNING: exception:",e)

        print("logging to ", filename)
        logging.basicConfig(level=logging.WARN,format='%(asctime)s %(name)s %(levelname)s %(message)s',filename=filename)
        logging.getLogger('zeep.client').setLevel(logging.DEBUG)
        logging.getLogger('zeep.Client').setLevel(logging.DEBUG)
        logging.getLogger('zeep.transports').setLevel(logging.DEBUG)
        logging.getLogger('zeep.Transports').setLevel(logging.DEBUG)
        logging.getLogger('zeep.wsdl').setLevel(logging.DEBUG)
        logging.getLogger('zeep.xsd').setLevel(logging.DEBUG)
        #logging.getLogger('suds.transports').setLevel(logging.DEBUG)
        #logging.getLogger('suds.xsd.schema').setLevel(logging.DEBUG)
        #logging.getLogger('suds.wsdl').setLevel(logging.DEBUG)
    
    def initBLConfig(self,blConf):
        # read the config
        if blConf:
            self.blConf = blConf
        else:
            self.blConf = blBase.getMyConf()

        self.wsConfig = configparser.RawConfigParser()
        self.blConfFile=self.getMyHome() + "/" + ".bl_tools/conf/" + self.blConf
        
        self.wsConfig.read(self.blConfFile)
        if self.debug: print(self.blConfFile)
        # set the service urls, and record the host
        self.loginUrl = self.wsConfig.get('Bladelogic', 'loginUrl')
        self.frontHost = self.loginUrl.split("//")[1].split(":")[0]
        self.roleUrl = self.wsConfig.get('Bladelogic', 'roleUrl')
        #self.baseRoleUrl = self.wsConfig.get('Bladelogic', 'baseRoleUrl')
        self.cliUrl = self.wsConfig.get('Bladelogic', 'cliUrl')
        #self.baseCliUrl = self.wsConfig.get('Bladelogic', 'baseCliUrl')
        # get the user, role, pass, group(i.e. where the jobs and scripts live)
        if not "BL_PASS" in os.environ:
            print("please run bl_pass")
            sys.exit(1)
        self.blUser = self.wsConfig.get('Bladelogic', 'blUser')
        self.blRole = self.wsConfig.get('Bladelogic','blRole')
        self.blPass = base64.b64decode(os.environ["BL_PASS"])
        self.myGroup = blBase.getMyGroup()
        #self.myGroup = os.environ.get('myGroup')
        self.defaultMyGroup = self.wsConfig.get('Bladelogic','defaultMyGroup')
        self.blPassType = self.wsConfig.get('Bladelogic','passType')

    def updateServiceUrls(self,fqdn):
        self.loginUrl = blBase.updateURLFQDN(self.loginUrl,fqdn)
        self.roleUrl = blBase.updateURLFQDN(self.roleUrl,fqdn)
        #self.baseRoleUrl = blBase.updateURLFQDN(self.baseRoleUrl,fqdn)
        self.cliUrl = blBase.updateURLFQDN(self.cliUrl,fqdn)
        #self.baseCliUrl = blBase.updateURLFQDN(self.baseCliUrl,fqdn)

    def edtTime(self):
        return pytz.timezone("EST").localize(datetime.datetime.now()).isoformat()

    def emailError(self,url,e):
            
        print("emailError(",url,e,")")
        self.initClientsEndTime = self.edtTime()
        
        text = "Start time: " + self.initClientsStartTime + "\n"
        text = text + "End time:" + str(self.initClientsEndTime) + "\n"
        text = text + "SessionId:" + str(self.sessionId) + "\n"
        text = text + "User:" + self.blUser + "\n"
        text = text + "Role:" + self.blRole + "\n"
        text = text + "serviceUrl:" + url + "\n"
        text = text + "\n\n" + str(e)
        
        print(text)

        if not os.environ["USER"].upper() == self.debuguser.upper(): return

        from subprocess import Popen
        process = Popen(["ssh",self.debugmailhost,"mail","-vv","-s","bl_tools.failed_login", "--", self.debugemail],stdin=PIPE, stdout=PIPE)
        process.stdin.write(bytes(text,'utf-8'))
        print(process.communicate()[0])
        process.stdin.close()
        
    def initClients(self,retry=False,failquick=False):
        if self.trynum > 1: print("login attempt "+str(self.trynum))
        self.trynum = self.trynum+1
        self.initClientsStartTime = self.edtTime()
        if retry and not failquick:
            if self.UIbackends:
                newfqdn = self.UIbackends.pop()
                print("WARN: client initialization failed against",self.loginUrl.split("/")[2])
                print("WARN: trying again with",newfqdn)
                self.updateServiceUrls(newfqdn)
            else:
                print("ERROR: no remaining backends to try.  Exiting.")
                sys.exit(1)

        ## set up some defaults for all of the clients
        self.Session=Session()
        self.Session.verify=False
        settings = zeep.Settings() #strict=False)
        self.Transport=zeep.transports.Transport(session=self.Session)
        
        ## login, and update everything to use the returned service host
        ## also, record the proxy host
        try:
            #print "==geting client"
            history = HistoryPlugin()
            self.loginClient = zeep.Client(self.loginUrl,transport=self.Transport,settings=settings,plugins=[history])
            #print "last sent:", history.last_sent, "--"
            #print "last recv:", history.last_received, "--"
            #print "last sent:", history.last_sent, "--"
            print("==client acquired:",self.loginClient)
            #print "==logging in"
            self.loginResult = self.BlLogin(self.loginClient,self.blUser, self.blPass, self.blPassType)
            #print "==login done"
            # separate out just the fqdn from teh returned serviceUrl
            try:
                embed()
                print("last_recv:",history.last_received)
                self.proxyHost = self.loginResult['return'].serviceUrl.split("//")[1].split(":")[0]
                self.serviceUrls = self.loginResult['return'].serviceUrls
                if self.debug: print("The login service is directing us from",self.loginUrl.split("//")[1].split(":")[0],"to BL appserver", self.proxyHost)
                self.updateServiceUrls(self.proxyHost)
            except: pass
        except Exception as e:
            print("\nLogin failed using",self.loginUrl,":", e)
            self.emailError(self.loginUrl,e)
            print("Please cut a ticket with",self.bladelogicticketurl)
            print("Trying again")
            return self.initClients(retry=True)
            #sys.exit(1)

        #record default soap headers.  sessionId allows to keep one session across the client instances
        self.sessionId = self.loginResult.returnSessionId
        self.soapheaders = {"request_header":self.sessionId}

        ## init assumeRole client
        print('Logged in as: '+self.blUser, file=sys.stderr)
        print('Session ID: ' + str(self.sessionId), file=sys.stderr)
        print('Switching role to: '+ self.blRole, file=sys.stderr)
        print("====")
        #for u in self.serviceUrls:
        #    u=re.sub(".*//","https://",u)
        #    print "later we can try",u,"- maybe try preserving the ports, or the wsdl location (under wsdl:port)"
        try:
            self.roleClient = Client(self.roleUrl,transport=self.Transport)
            self.roleClient.set_default_soapheaders(self.soapheaders)
            assume_result = self.roleClient.service.assumeRole(self.blRole)
        except Exception as e:
            print("assumeRole exception:",e)
            print("Trying again")
            self.emailError(self.roleUrl,e)
            return self.initClients(retry=True)
            #sys.exit(1)
        if assume_result != self.blRole:
            print("could not switch to role:", self.blRole)
            sys.exit(1)    

        ## init runBlcli client
        try:
            self.blCliClient = Client(self.cliUrl,transport=self.Transport)
            self.blCliClient.set_default_soapheaders(self.soapheaders)
        except Exception as e:
            print("initial setup of blCliClient failed against",self.cliUrl,":",e)
            self.emailError(self.cliUrl,e)
            return self.initClients(retry=True)
        try:
            self.blCliClient2 = Client(self.cliUrl,transport=self.Transport)
            self.blCliClient2.set_default_soapheaders(self.soapheaders)
        except Exception as e:
            print("initial setup of blCliClient2 failed against",self.cliUrl,":",e)
            self.emailError(self.cliUrl,e)
            return self.initClients(retry=True)

    def initSettings(self):
        import json
        file = open(settingsFile,mode="rt")
        SETTINGS = json.load(file)
        self.bladelogicticketurl = SETTINGS["bladelogicticketurl"]
        self.debuguser = SETTINGS["debuguser"]
        self.debugemail = SETTINGS["debugemail"]
        self.debugmailhost = SETTINGS["debugmailhost"]
        self.ns = SETTINGS["ns"]
        
    def initAlternateURLs(self):
        POD=""

        file = open(self.UIfile,mode="rt")
        ALL_UI=json.load(file)
        vip = ALL_UI["vip"]
        vip_addr = socket.gethostbyname(vip)
        vip1 = ALL_UI["vip1"]
        vip1_addr = socket.gethostbyname(vip1)
        vip2 = ALL_UI["vip2"]
        vip2_addr = socket.gethostbyname(vip2)

        #print("vip =",vip,"vip1 =",vip1,"vip2 =",vip2)
        if vip_addr == vip1_addr: POD="POD1"
        elif vip_addr == vip2_addr: POD="POD2"
        else:
            print("ERROR:", vip,"(",vip_addr,")is not pointing at", vip1, "(",vip1_addr,") or ",vip2,"(",vip2_addr,")")
            sys.exit(1)

        self.UIbackends=ALL_UI[POD]
        #self.UI=json.load(file)

    def __init__(self,debug=False,bl_conf=None,failquick=False):
        self.initLogging()
        self.debug=debug
        self.initAlternateURLs()
        self.initSettings()
        #print("UIbackends: ", self.UIbackends)
        if not "myRole" in os.environ:
            print("no role is set.  please run bl_conf.")
            sys.exit(1)
        try:
            self.initBLConfig(bl_conf)
        except Exception as e:
            self.writeHeader
            print("Unable to read configuration. please check", self.blConfFile)
            self.writeFooter
            print(self.f_loc()+":",e)
            sys.exit(1)
        
        self.initClients(failquick=failquick)

        #try:
        #    print "getting cursor"
        #    self.rbCursor = pymssql.connect("host:port","domain\\user",'password',"dbname",appname="bl_tools").cursor()
        #    print "aquired cursor",self.rbCursor
        #except: pass
        self.initServerMap()

    def finishup(self,status):
        if self.loginattempts>0:
            import socket
            origurl=self.wsConfig.get('Bladelogic', 'loginUrl')
            print("\n\n=============================\n\n")
            print("Multiple login urls were tried")
            print("First try was against",origurl) 
            fqdn = origurl.split("/")[2].split(":")[0]
            ip=None
            try:
                ip = socket.gethostbyname(fqdn)
                print("this resolves to",ip)
            except:
                print("this fqdn does not resolve in dns.")
            print("please cut a ticket to",self.bladelogicticketurl)
            print("\n\n=============================\n\n")
        # if True, exit 0; If False, exit 1
        sys.exit(int(not int(status)))


#==== END UTILITIES ====
from requests.packages.urllib3.exceptions import InsecureRequestWarning, InsecurePlatformWarning, SNIMissingWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
requests.packages.urllib3.disable_warnings(InsecurePlatformWarning)
requests.packages.urllib3.disable_warnings(SNIMissingWarning)
from xml.etree import ElementTree

configfile = open("/unixworks/bl_tools/etc/settings.json","rt")
config = json.load(configfile)
ns = config["ns"]
statusurl = config["statusurl"]
permsurl = config["permsurl"]
roletoadurl = config["roletoadurl"]

def blStatus(fqdn):
    url = statusurl + fqdn
    headers = {'Content-Type': 'application/xml'}
    response = requests.get(url,headers=headers,verify=False)
    tree = ElementTree.fromstring(response.content)
    return {"enrolled":tree.find('status:enrolled', ns).text, "ping":tree.find('status:ICMPstatus',ns).text,"rscd":tree.find('status:RSCDstatus',ns).text, "servername":tree.find('status:ServerName',ns).text }

def blPerms(fqdn):
    url = permsurl + fqdn
    headers = {'Content-Type': 'text/xml'}
    content = requests.get(url,headers=headers,verify=False).content
    return re.search(b'Permissions>(.*)<\/Permissions', content).group(1).split(b' ')

def blSAMs(fqdn): return [x for x in blPerms(fqdn) if re.search(b'SAM_',x)]
def blRoles(fqdn): return [x for x in blPerms(fqdn) if not re.search(b'SAM_',x)]
def blCustomUnixRoles(fqdn): return [x for x in blRoles(fqdn) if re.search(b'CUSTOM',x) and re.search(b'UNIX',x)]
