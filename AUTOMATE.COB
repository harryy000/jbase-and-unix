*-----------------------------------------------------------------------------
* <Rating>60</Rating>
*-----------------------------------------------------------------------------
    PROGRAM AUTOMATE.COB
*------------------------------------------------------------------------------------------------------------------
* This is the automatic program that starts cob.So we do the below checks before we start cob
* If backup is sucessfull a file called TODAY_0 will be created by backup script,we will check that,if it is TODAY_1,then
* we will stop the process and send an email
* We check if the backup for today is taken
* Then we check if any services/zombies are running
* Then run EODSTART
* Then finally run START.TSM
* This program will be triggered from a VBA script from windows,that will open anzio and run this AUTOMATE.COB program
* Harish A.S. 29th Oct 2014
* Fixing when date is single digit(1st to 1oth of any month it would fail),so getting the unix date from 4th value after space rather than 3rd
* Harish A.S. 4th Nov 2014
*------------------------------------------------------------------------------------------------------------------------

    $INSERT I_COMMON
    $INSERT I_EQUATE

*Formalities first
    CALL OVERLAY.EX
    CALL LOAD.COMPANY('NL0010001')

* Check for  the file TODAY_0 .This file will be created by backupscript on sucessfull completion of the backup
    OPEN '/u05/globus' TO MASTER.PTR ELSE NULL
    FILE.NAME=TODAY:"_0"
    READ R.DATA FROM MASTER.PTR,FILE.NAME ELSE
        SRV=''
        SUBJECT= "BACKUP alert"
*        RCPT= "harish@tebnv.nl"
        RCPT= "globususernotification@tebnv.nl"
        CHANGE "/" TO " " IN FINAL.BACKUP.DATE
        CHANGE "/" TO " " IN FINAL.UNIX.DATE
        MSG= 'Backup file ':FILE.NAME:' missing'
        CMD=\SH -c "echo '\:MSG:\' | mailx  -s '\:SUBJECT:\' \:RCPT:\"\
        CRT CMD
        EXECUTE CMD
        STOP
    END
**2nd level check.Check the unix date and then check if the backup taken and stored in /u05/globus have
**the same date
    EXECUTE '/usr/bin/date +%A' CAPTURING DAY
    REQD.DAY=DAY[1,3]
    DELIM='"/"'
    BACKUP.DATE=" | awk '{print $6,":DELIM:",$7":DELIM:",$9}'"
    CMD.DAY="SH -c ls -lrt /u05/globus | grep ":DAY:BACKUP.DATE
    EXECUTE CMD.DAY CAPTURING BACKUP.DATA
    CHANGE " " TO "" IN BACKUP.DATA
    FINAL.BACKUP.DATE=FIELD(BACKUP.DATA,"/",3)[1,3]:"/":FIELD(BACKUP.DATA,"/",1):"/":FIELD(BACKUP.DATA,"/",2)
    CRT FINAL.BACKUP.DATE
    EXECUTE "date" CAPTURING UNIX.DATE
    FINAL.UNIX.DATE=FIELD(UNIX.DATE," ",1):"/":FIELD(UNIX.DATE," ",2):"/":FIELD(UNIX.DATE," ",3)
* S/4th Nov 2014
    IF FIELD(UNIX.DATE," ",3) EQ '' THEN
        FINAL.UNIX.DATE=FIELD(UNIX.DATE," ",1):"/":FIELD(UNIX.DATE," ",2):"/":FIELD(UNIX.DATE," ",4)
    END ELSE
        FINAL.UNIX.DATE=FIELD(UNIX.DATE," ",1):"/":FIELD(UNIX.DATE," ",2):"/":FIELD(UNIX.DATE," ",3)
    END
* E/4th Nov 2014
    CRT FINAL.UNIX.DATE
    IF FINAL.UNIX.DATE NE FINAL.BACKUP.DATE THEN
        SRV=''
        SUBJECT= "BACKUP alert"
*        RCPT= "harish@tebnv.nl"
        RCPT= "globususernotification@tebnv.nl"
*        MSG= 'Backup file missing for ':TODAY:"Today's unix date ":FINAL.UNIX.DATE:'.But latest backup taken for ':DAY:' is ':FINAL.BACKUP.DATE
        MSG= 'Backup for today missing ':TODAY:'(':DAY:')':'.Todays unix date is ':FINAL.UNIX.DATE:'.But latest backup date for ':DAY:' is ':FINAL.BACKUP.DATE

        CMD=\SH -c "echo '\:MSG:\' | mailx  -s '\:SUBJECT:\' \:RCPT:\"\
        CRT CMD
        EXECUTE CMD
        STOP
    END
* Check for agents running,if no agets or zombies are present then it will clear the TSA.STATUS and SESSION records that are expired.
* If there are zombies or active agents,we will stop the process and send an email
    EXECUTE "CLRSTATUS" CAPTURING OUTPUT

    FINDSTR "Below Services are Active" IN OUTPUT SETTING ACTIVE.POS THEN
        SRV=''
        SUBJECT= "CLRSTATUS alert"
*        RCPT= "harish@tebnv.nl"
        RCPT= "globususernotification@tebnv.nl"
        TOT.OUTPUT=DCOUNT(OUTPUT,FM)
        FOR I=ACTIVE.POS TO TOT.OUTPUT
            SRV<-1>=OUTPUT<I>
        NEXT I
        MSG= 'CLRSTATUS says ':SRV
        CHANGE FM TO " " IN MSG
        CMD=\SH -c "echo '\:MSG:\' | mailx  -s '\:SUBJECT:\' \:RCPT:\"\
        CRT CMD
        EXECUTE CMD
        CRT "Sending email ":CMD
        STOP
    END ELSE
* If the aobe process is successfull we will start COB by doing EODSTART.If COB is already run,then we will stop here and send an email
        CRT "Sucessfully cleared TSA.STATUS"
        EXECUTE "EODSTART" CAPTURING COB.START
        FINDSTR "Error:" IN COB.START SETTING COB.START.POS THEN
            CRT "COB already run"
            MSG='COB Already run'
            SUBJECT= "EODSTART alert"
*            RCPT= "harish@tebnv.nl"
            RCPT= "globususernotification@tebnv.nl"
            CMD=\SH -c "echo '\:MSG:\' | mailx  -s '\:SUBJECT:\' \:RCPT:\"\
            CRT CMD
            EXECUTE CMD
            STOP
        END ELSE
* Finally if all the above processess are done we will pull the trigger for COB-START.TSM
            EXECUTE "START.TSM"
        END
    END

    STOP
