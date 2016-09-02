#!/bin/sh
### NAME:      mqconfig
###
### VERSION:   3.7
###
### AUTHOR:    Justin Fries (justinf@us.ibm.com)
###
### COPYRIGHT:
### 
### (C) COPYRIGHT International Business Machines Corp. 2007-2013
### All Rights Reserved
### Licensed Materials - Property of IBM
###
### US Government Users Restricted Rights - Use, duplication or
### disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
###
### SYNOPSIS:
###
###  mqconfig -?
###  mqconfig -v Version
###  mqconfig -v Version [-p Project]...     (Solaris 10+ only)
###
###         -?: Display help for the mqconfig script
###         -v: WebSphere MQ version: 7.5, 7.1 or 7.0
###         -p: A project name to check
###
### DESCRIPTION:
###
### This script validates kernel parameters and other resource limits on
### AIX, HP-UX, Linux and Solaris systems against the recommendations in
### the WebSphere MQ documentation:
###
###   http://www.ibm.com/software/integration/wmq/library/
###
###
### CAVEATS/WARNINGS:
###
### Successful validation by this script only confirms your system meets
### the default recommendations.  If your system is heavily stressed, if
### you are running many queue managers at once, or if your system hosts
### other programs like databases which make heavy resource demands, you
### may need to increase your settings beyond the default values.
###
### Where possible this script issues a warning for parameters which are
### lower than recommended but sufficient for a small system.  Generally
### values at 75% or better of the recommended limit cause a warning and
### not a failure, but be aware WebSphere MQ can fail if it exhausts the
### resource on your system.  For further guidance see:
###
###   http://www.ibm.com/support/docview.wss?uid=swg21271236
###
### Certain limits are defined on a per-user basis, e.g. with the ulimit
### shell command.  These limits should be configured for the 'mqm' user
### so that queue managers started by mqm (directly, or using sudo) will
### run with the properly limits.  However, WebSphere MQ commands can be
### run by any user in the 'mqm' group, and sometimes by anybody.  Since
### the mqconfig script does not know what users will start WebSphere MQ
### processes on your system, it shows limits for the current user only.
### You can run mqconfig as mqm, as root, and again as any other user on
### the system to verify that those logins have the proper limits to run
### WebSphere MQ commands.
###
###
### RETURNED VALUES:
###
###   0  - Passed all tests
###   1  - Passed with warnings
###   2  - Failed some tests
###
###
### EXAMPLES:
###
### 1. To check your settings for WebSphere MQ 7.5:
###
###      mqconfig -v 7.5
###
###
### 2. To check the group.mqm and mqdev projects on Solaris 10+ for
###    WebSphere MQ 7.1:
###
###      mqconfig -p group.mqm -p mqdev -v 7.1
###
###
### 3. To get help with the mqconfig script:
###
###      mqconfig -?
###




### The Message function formats messages with caller-supplied values to
### fit an 80-character line and writes them to stdout.  In some Solaris
### shells the getopt builtin does not allow us to identify which option
### flag caused the error, so we suppress those messages.

  Message() {
    MSGID=$1; shift

    { case "${MSGID:=9999}" in
        1000) if [ -z "$1" ]; then
                return 0
              fi

              cat <<- :END
		Option -$1 requires an argument.
		:END
              ;;

        1001) if [ -z "$1" ]; then
                return 0
              fi

              cat <<- :END
		Option -$1 is not valid.
		:END
              ;;

        1002) cat <<- :END
		You must provide a WebSphere MQ version.
		:END
              ;;

        1003) cat <<- :END
		WebSphere MQ V$1 is not supported.
		:END
              ;;

        1004) cat <<- :END
		Unexpected parameters: $@
		:END
              ;;

        1005) cat <<- :END
		V3.7 analyzing $1 settings for WebSphere MQ V$2
		:END
              ;;

        1006) cat <<- :END
		This script does not support $@.
		:END
              ;;

        1007) cat <<- :END
		Project $1 does not exist.
		:END
              ;;

        1008) cat <<- :END
		No project given.  Analyzing $@.

		:END
              ;;

        1009) cat <<- :END
		WebSphere MQ V$1 does not exist.
		:END
              ;;

        1010) cat <<- :END
		WebSphere MQ V$1 does not support $2 $3.
		:END
              ;;

        1011) cat <<- :END
		WebSphere MQ V$1 is no longer supported by this script.
		Please download the mqconfig-old script from the IBM site in
		order to analyze a WebSphere MQ V6.0 or V5.3 system.
		:END
              ;;

        1012) cat <<- :END
		WebSphere MQ V7.0 requires AIX 5.3 Technology Level 4 or later,
		and at Technology Level 5 it requires Service Pack 2 or later,
		and at Technology Level 7 it requires Service Pack 1 or later.
		Please refer to the Systems Requirement page on the web for
		further details and current status.
		:END
              ;;

        1013) cat <<- :END
		WebSphere MQ V$1 requires AIX 6.1 Technology Level 5 or later.
		:END
              ;;

        1014) cat <<- :END
		You have a group.mqm project configured, but have started one or
		more queue managers under other projects $1.  Start WebSphere MQ
		as someone whose primary group is mqm, or use the newtask command
		to ensure queue managers run in the correct project.
		:END
              ;;

        1015) cat <<- :END
		You do not have a group.mqm project configured.  IBM recommends
		that you configure a group.mqm project with resource limits for
		WebSphere MQ, but you can run queue managers under other projects.
		If you plan to use a different project for WebSphere MQ, rerun
		mqconfig with the -p option to analyze that project.
		:END
              ;;

        1016) cat <<- :END
		The $1 program was not found on this system.  Please install
		$1 and try running mqconfig again.
		:END
              ;;

           *) cat <<- :END
		Cannot print message: $MSGID $@
		:END
              ;;
      esac } | env LANG=C tr -d '\t' | fmt -68 | {
        read LINE && printf "mqconfig: $LINE\n"
        while read LINE; do
          printf "          $LINE\n"
        done
    }

    return 0
  }


### The Error function prints a message to stderr, and optionally prints
### the message to stdout when stdout is redirected to a file.  Provided
### the shell supports the '-t' test, this ensures that IBM will receive
### a file which includes any errors reported to the user.

  Error() {
    Message "$@" >&2

    if [ -t 2 -a ! -t 1 ]; then
      Message "$@"
    fi

    return 0
  }


### Print the script syntax for this operating system to stderr.

  PrintSyntax() {
    printf "\n%s\n" "syntax:   mqconfig -?" >&2

    case "$OPSYS" in
      Solaris*) printf "%s\n" "          mqconfig -v Version [-p Project] ..." >&2
                ;;

             *) printf "%s\n" "          mqconfig -v Version" >&2
                ;;
    esac

    printf "\n          Version: 7.5, 7.1 or 7.0\n" >&2
    return 0
  }


### The PrintHelp function displays information about how mqconfig works
### and addresses frequently asked questions from users.  This method is
### invoked when a user runs 'mqconfig -?'.

  PrintHelp() {
    cat <<- :END
	Using mqconfig
	`PrintSyntax 2>&1 | sed 's/^/  /'`

	  The mqconfig script analyzes your AIX, HP-UX, Linux or Solaris system to make
	  sure its kernel paramaters and other settings match the values recommended by
	  IBM in the WebSphere MQ documentation.  For each parameter, mqconfig displays
	  the current value, the current resource usage where possible, the recommended
	  setting from IBM, and a PASS/WARN/FAIL grade.

	  The grade assigned to each setting is based on its proximity to the IBM value
	  and your resource usage.  For example, if the IBM recommended value is 10000,
	  a setting of 2000 will fail, 8000 will give a warning, and 10000 or more will
	  pass.  However, mqconfig will issue a warning if your system's resource usage
	  is high (typically 75% or more) even if your system meets the IBM recommended
	  value.  If your system is about to exhaust a resource (95% or more), mqconfig
	  will report that as a failure.  In such cases, you may need to choose a value
	  which exceeds the default IBM recommendation.


	User Limits

	  Certain resource limits affecting WebSphere MQ are user specific, and are set
	  using the ulimit shell command.  Even though WebSphere MQ effectively runs as
	  the mqm user, the resource limits applicable to the queue manager derive from
	  the shell of the user who starts it.  The mqconfig script displays the limits
	  for the current user only, so you should run mqconfig as mqm, or root, or any
	  other user who will start queue managers to ensure their resource limits will
	  not prevent the queue manager from running properly.


	Shell Options

	  The WebSphere MQ documentation warns of potential performance problems caused
	  by starting WebSphere MQ commands in a shell which runs background tasks at a
	  lower priority.  The mqconfig script will try to determine whether your shell
	  includes an option to reduce the priority of background processes, and if so,
	  it will show the current default.  If mqconfig identifies a problem with your
	  shell options, you can change them in your profile.  For example, 'ksh' users
	  can add the line 'set +o bgnice' to their profile to avoid this issue.


	Planning for Heavy Workloads

	  WebSphere MQ resource usage depends on how heavily you are using WebSphere MQ
	  including the number of channels, the number of clients, the number of queues
	  and messages on them.  A single busy queue manager may use far more resources
	  than ten test queue managers with light usage.  If you are using WebSphere MQ
	  very heavily, you should run mqconfig while processing your workload in order
	  to ensure that WebSphere MQ is not about to exhaust any resources.  It may be
	  necessary to increase your resource limits beyond the defaults recommended by
	  IBM in order to process heavy workloads.

	:END

    if [ $OPSYS = Solaris ]; then
      cat <<- :END

	Solaris Projects

	  Solaris does not have a single global set of kernel parameters.  Instead, you
	  must create projects, each with its own resource limits.  IBM recommends that
	  you create a project called group.mqm for WebSphere MQ, but you can choose to
	  run WebSphere MQ under any projects you wish.  Refer to the documentation for
	  the newtask command to see how to run WebSphere MQ under the right project.

	  Run mqconfig with the -p option to indicate which projects which are used for
	  running WebSphere MQ queue managers.  You can repeat the -p option to provide
	  a list of projects for mqconfig to analyze.  If you do not list any projects,
	  mqconfig will analyze the group.mqm project and any other projects which show
	  WebSphere MQ queue manager activity.  If there are no such projects, mqconfig
	  will analyze the current project.  If mqconfig gives warnings or failures for
	  project not intended for WebSphere MQ, rerun mqconfig with the '-p' option.

	:END
    fi

    return 0
  }


### The Sum function is a helper to sum up columns of numbers, while the
### Trim function removes leading and trailing space from values (useful
### when dealing with the output from 'wc -l').

  Sum() {
    SUM=0

    while read NUM ; do
      SUM=`expr $SUM + $NUM`
    done

    printf "$SUM"
  }


  Trim() {
    sed -e 's/^[ 	]*//' -e 's/[ 	]*$//'
  }


### Determine the current usage of those kernel parameters for which the
### operating system provides a method.  These results will be reflected
### in the output as a percentage of resources consumed.  For the number
### of processes per user we look at the number of processes running for
### the current user and any others with active queue manager processes,
### except for root, and print the highest value.  Although WebSphere MQ
### processes have an effective user of mqm, they count against the real
### user for accounting purposes.

  GetResourceUsage() {
    PARAM=$1

    case $OPSYS:$PARAM in
            Linux:file-max) GetLinuxValue fs.file-nr sys/fs/file-nr | awk '{print $1}'
                            ;;

      *:maxup*|Linux:nproc) { for USER in `id -un 2>/dev/null` `env UNIX95=1 ps -e -o user= -o comm= |
                               grep -E '[a]mqzxma0|[a]mqzmgr0' | awk '{print $1}' | sort -u`; do

                                if [ $USER != root ]; then
                                  env UNIX95=1 ps -o pid= -u $USER | wc -l
                                fi
                              done

                              printf "0\n"
                            } | sort -rn | head -n 1 | Trim
                            ;;

       Solaris:max-sem-ids) ipcs -sJ 2>/dev/null | grep -w $PROJECT | grep '^s' | wc -l | Trim
                            ;;

       Solaris:max-shm-ids) ipcs -mJ 2>/dev/null | grep -w $PROJECT | grep '^m' | wc -l | Trim
                            ;;

              Linux:semmni) ipcs -s 2>/dev/null | grep '^0x' | wc -l | Trim
                            ;;

         *:semmni|*:SEMMNI) ipcs -s 2>/dev/null | grep '^s' | wc -l | Trim
                            ;;

              Linux:semmns) ipcs -s 2>/dev/null | grep '^0x' | awk '{print $5}' | Sum
                            ;;

         *:semmns|*:SEMMNS) ipcs -sa 2>/dev/null | grep '^s' | sed 's/^./& /' |
                            awk '{print $9}' | Sum
                            ;;

              Linux:shmall) ipcs -u 2>/dev/null | grep 'pages allocated' | awk '{print $3}'
                            ;;

              Linux:shmmni) ipcs -m 2>/dev/null | grep '^0x' | wc -l | Trim
                            ;;

         *:shmmni|*:SHMMNI) ipcs -m 2>/dev/null | grep '^m' | wc -l | Trim
                            ;;
    esac
  }


### The DisplayLimit function compares the current value of an operating
### system parameter to the limit recommended by IBM, and where possible
### shows the current resource usage.  In addition to the IBM limit this
### function accepts an optional warning limit, expressed as an absolute
### value or as a percentage of the IBM limit.  Values which do not meet
### the IBM limit but are reasonably close will receive a warning.  When
### the warning limit is greater than the IBM limit, the parameter needs
### a low value; Simply negating all the values allows the same logic to
### calculate the grade.  We use bc to perform all comparisons and math,
### except for unknown or unlimited values, since it is easy to overflow
### the arithmetic precision of the shell.  After printing the parameter
### name, value, current usage (where possible), and the IBM recommended
### limit, this function assigns a grade based on these basic rules:
###
###  PASS: Meets or exceeds the IBM value and usage is less than 75%
###  WARN: Limit approaches the IBM value or usage is between 75-95%
###  FAIL: Limit is less than the IBM value or its usage exceeds 95%

  DisplayLimit() {
    PARAM=$1
    UNITS=$2
    VALUE=$3
    LIMIT=$4
    ALERT=$5

    CURRENT=`GetResourceUsage $PARAM`
    if [ -z "$LIMIT" ]; then
      return
    elif [ -z "$VALUE" ]; then
      return
    elif [ "$UNITS" = "$LITERAL" ]; then
      printf "  %-19s %-34s %-17s %b\n" "$PARAM" "$VALUE" "IBM:$LIMIT" "$ALERT"
      return
    elif [ "$LIMIT" = "$AUTO" ]; then
      printf "  %-19s %-34s %-17s %b\n" "$PARAM" "${CURRENT:=$UNKNOWN} $UNITS" "[Auto Tuned]" $PASS
      return
    elif [ -n "$CURRENT" -a "$VALUE" != "$UNKNOWN" -a "$VALUE" != "$UNLIMITED" ]; then
      PERCENT=`printf "$CURRENT * 100 / $VALUE\n" | bc 2>/dev/null`
      printf "  %-19s %-26s %-7s " "$PARAM" "$CURRENT of $VALUE $UNITS" "(${PERCENT}%)"
    else
      PERCENT=0
      printf "  %-19s %-34s " "$PARAM" "$VALUE $UNITS"
    fi

    case ${ALERT:=$LIMIT} in
      *%) ALERT=`printf "%s" "$ALERT" | env LANG=C tr -d %`
          ALERT=`printf "$LIMIT * $ALERT / 100\n" | env LANG=C tr -d % | bc 2>/dev/null`
          ;;
    esac

    if [ "$LIMIT" != "$UNLIMITED" -a -n "`printf \"if ($ALERT > $LIMIT) 1\n\" | bc 2>/dev/null`" ]; then
      if [ $LIMIT -eq 1 ]; then
        printf "%-17s " "IBM=$LIMIT"
      else
        printf "%-17s " "IBM<=$LIMIT"
      fi

      LIMIT=-$LIMIT; ALERT=-$ALERT; VALUE=-$VALUE
    else
      printf "%-17s " "IBM>=$LIMIT"
    fi

    if [ "$VALUE" = "$UNLIMITED" ]; then
      printf "%b\n" $PASS
    elif [ "$VALUE" = "$UNKNOWN" -o "$LIMIT" = "$UNLIMITED" ]; then
      WARNINGS=`expr $WARNINGS + 1`
      printf "%b\n" $WARN
    elif [ -n "`printf \"if ($VALUE < $ALERT) 1\n\" | bc 2>/dev/null`" -o $PERCENT -gt 95 ]; then
      FAILURES=`expr $FAILURES + 1`
      printf "%b\n" $FAIL
    elif [ -n "`printf \"if ($VALUE >= $LIMIT) 1\n\" | bc 2>/dev/null`" -a $PERCENT -lt 75 ]; then
      printf "%b\n" $PASS
    else
      WARNINGS=`expr $WARNINGS + 1`
      printf "%b\n" $WARN
    fi

    return
  }


### The WebSphere MQ documentation notes that shells with some notion of
### bgnice (reducing the priority of background processes) can introduce
### performance problems.  When a user starts commmands like runmqlsr in
### the background ('runmqlsr -m QM -t tcp -p 1414 1>/dev/null 2>&1 &'),
### those commands may hold WebSphere MQ locks longer than usual as they
### are runnning at reduced priority.  It is impossible to test the user
### shell since mqconfig is running in its own shell (/bin/sh).  However
### we can determine which shell is the parent to mqconfig and use it to
### determine the default value of bgnice or similar settings.  The test
### is not a perfect one, so any failure will at most provoke a warning.
### Shells with no notion of bgnice will not generate any output at all.
### From my testing, Bourne and bash shells have no bgnice, while shells
### based on Korn (ksh, pdksh) do.  The zsh shell has a nobgnice option,
### which is the exact inverse of bgnice.  When this function detects an
### option like bgnice, it calls DisplayLimit passing literal values for
### the current and IBM values as opposed to numeric values, and a score
### for the current setting.

  CheckShellDefaultOptions() {
    PSHID=`env UNIX95=1 ps -o ppid= -p $$ 2>/dev/null`
    PSHELL=`env UNIX95=1 ps -o comm= -p $PSHID 2>/dev/null | sed 's/^-*//'`
    OLDIFS="$IFS"
    IFS='
'

    for SETTING in `$PSHELL -ic "set -o" 2>/dev/null | grep bgnice`; do
      case $SETTING in
        nobgnice*off) printf "\nShell Default Options (%s)\n" "`id -un 2>/dev/null`"
                      DisplayLimit "$PSHELL" $LITERAL "nobgnice:off" on $WARN
                      ;;

         nobgnice*on) printf "\nShell Default Options (%s)\n" "`id -un 2>/dev/null`"
                      DisplayLimit "$PSHELL" $LITERAL "nobgnice:on" on $PASS
                      ;;

          bgnice*off) printf "\nShell Default Options (%s)\n" "`id -un 2>/dev/null`"
                      DisplayLimit "$PSHELL" $LITERAL "bgnice:off" off $PASS
                      ;;

           bgnice*on) printf "\nShell Default Options (%s)\n" "`id -un 2>/dev/null`"
                      DisplayLimit "$PSHELL" $LITERAL "bgnice:on" off $WARN
                      ;;
      esac
    done

    IFS="$OLDIFS"
  }


### AIX is special in that the kernel has no parameters for System V IPC
### resources; Instead, AIX supports such large values that WebSphere MQ
### cannot exhaust them, even with databases and other IPC users running
### on the same system.  This function prints the current usage of these
### parameters before checking other settings on the system.  Given that
### there are operating system HIPER APARs which affect WebSphere MQ, we
### also print their installation status on affected levels of AIX.  The
### instfix command may lack the data to accurately report the status of
### the APARs, so instead we look at the affected LPP versions:
###
###   AIX V7.1 TL0: bos.mp64 7.1.0.0 - 7.1.0.1 are vulnerable
###                 bos.mp64 7.1.0.2 and later include IZ84576
###            TL1: bos.mp64 7.1.1.0 and later are not vulnerable
###
###   AIX V6.1 TL6: bos.mp64 6.1.6.0 - 6.1.6.1 are vulnerable
###                 bos.mp64 6.1.6.2 - 6.1.6.14 include IZ84729
###                 bos.mp64 6.1.6.15 and later include IZ85204
###            TL7: bos.mp64 6.1.7.0 and later are not vulerable
###
### AIX customers often report data conversion problems when they do not
### have the necessary AIX Unicode conversion LPPs installed.  There are
### six conversion LPPs right now, of which three are always checked and
### the remaining ones may be checked based on the current locale.

  AnalyzeAIX() {
    IBM_MAXUPROC=1024
    IBM_NOFILES_HARD=10240
    IBM_NOFILES_SOFT=10240
    IBM_DATA_SOFT=$UNLIMITED
    IBM_STACK_SOFT=$UNLIMITED

    CUR_MAXUPROC=`lsattr -El sys0 -a maxuproc 2>/dev/null | awk '{print $2}'`
    CUR_NOFILES_HARD=`ulimit -Hn 2>/dev/null`
    CUR_NOFILES_SOFT=`ulimit -Sn 2>/dev/null`
    CUR_DATA_SOFT=`ulimit -Sd 2>/dev/null`
    CUR_STACK_SOFT=`ulimit -Ss 2>/dev/null`

    ABSTRACT="Applications using user trace hooks fail when trace is enabled"

    case "`lslpp -qcL bos.mp64 2>/dev/null | awk -F: '{print $3}'`" in
       7.1.0.[0-1]) printf "\nOperating System HIPER APARs\n"
                    printf "  %7s: %-63s %b\n" IZ84576 "$ABSTRACT" $FAIL
                    ;;

           7.1.0.*) printf "\nOperating System HIPER APARs\n"
                    printf "  %7s: %-63s %b\n" IZ84576 "$ABSTRACT" $PASS
                    ;;

       6.1.6.[0-1]) printf "\nOperating System HIPER APARs\n"
                    printf "  %7s: %-63s %b\n" IZ84729 "$ABSTRACT" $FAIL
                    ;;

       6.1.6.[2-9]) printf "\nOperating System HIPER APARs\n"
                    printf "  %7s: %-63s %b\n" IZ84729 "$ABSTRACT" $PASS
                    ;;

      6.1.6.1[0-4]) printf "\nOperating System HIPER APARs\n"
                    printf "  %7s: %-63s %b\n" IZ84729 "$ABSTRACT" $PASS
                    ;;

           6.1.6.*) printf "\nOperating System HIPER APARs\n"
                    printf "  %7s: %-63s %b\n" IZ85204 "$ABSTRACT" $PASS
                    ;;
    esac

    printf "\nSystem V Semaphores\n"
    DisplayLimit semmni                sets        0                       "$AUTO"
    DisplayLimit semmns                semaphores  0                       "$AUTO"

    printf "\nSystem V Shared Memory\n"
    DisplayLimit shmmni                sets        0                       "$AUTO"

    printf "\nSystem Settings\n"
    DisplayLimit maxuproc              processes  "$CUR_MAXUPROC"          "$IBM_MAXUPROC"       50%

    printf "\nUnicode Filesets used by WebSphere MQ Data Conversion\n"
    UCSLPPS="bos.iconv.ucs.com bos.iconv.ucs.ebcdic bos.iconv.ucs.pc"

    case "$LANG" in
            ZH_CN*|Zh_CN*) UCSLPPS="$UCSLPPS bos.iconv.ucs.ZH_CN bos.iconv.ucs.Zh_CN"
                           ;;

      Et_EE*|Lt_LT*|Lv_LV) UCSLPPS="bos.iconv.ucs.baltic $UCSLPPS"
                           ;;
    esac

    for LPPNAME in $UCSLPPS; do
      LPPSTAT=$PASS; lslpp -L $LPPNAME 1>/dev/null 2>&1 || LPPSTAT=$WARN

      case $LPPNAME in
        bos.iconv.ucs.baltic) LPPDESC="Unicode Converters for Baltic Countries"
                              ;;

           bos.iconv.ucs.com) LPPDESC="Unicode Converters for AIX Code Sets/Fonts"
                              ;;

        bos.iconv.ucs.ebcdic) LPPDESC="Unicode Converters for EBCDIC Code Sets"
                              ;;

            bos.iconv.ucs.pc) LPPDESC="Unicode Converters for Additional PC Code Sets"
                              ;;

         bos.iconv.ucs.ZH_CN) LPPDESC="Unicode Converters for Simplified Chinese (UTF)"
                              ;;

         bos.iconv.ucs.Zh_CN) LPPDESC="Unicode Converters for Simplified Chinese (GBK)"
                              ;;
      esac

      printf "  %-20.20s  %-49.49s  %b\n" $LPPNAME "$LPPDESC" $LPPSTAT
    done

    printf "\nCurrent User Limits (%s)\n" "`id -un 2>/dev/null`"
    DisplayLimit "nofiles      (-Hn)"  files       "$CUR_NOFILES_HARD"     "$IBM_NOFILES_HARD"   75%
    DisplayLimit "nofiles      (-Sn)"  files       "$CUR_NOFILES_SOFT"     "$IBM_NOFILES_SOFT"   75%
    DisplayLimit "data         (-Sd)"  kbytes      "$CUR_DATA_SOFT"        "$IBM_DATA_SOFT"      75%
    DisplayLimit "stack        (-Ss)"  kbytes      "$CUR_STACK_SOFT"       "$IBM_STACK_SOFT"     75%

    CheckShellDefaultOptions
  }



### HP-UX 11 provides the kctune command for querying and setting kernel
### parameters, or on earlier releases the kmtune command.  As the value
### may be in hex or octal, use bc to normalize it to decimal.

  GetHPUXValue() {
    PARAM=$1
    VALUE=

    if [ -x /usr/sbin/kctune ]; then
      VALUE=`/usr/sbin/kctune $PARAM 2>/dev/null | grep "^$PARAM" |
        awk '{print $2}' | env LANG=C tr [:lower:] [:upper:]`
    elif [ -x /usr/sbin/kmtune ]; then
      VALUE=`/usr/sbin/kmtune -q $PARAM 2>/dev/null | grep "^$PARAM" |
        awk '{print $2}' | env LANG=C tr [:lower:] [:upper:]`
    fi

    case $VALUE in
      0[xX]*) printf "ibase=16; %s\n" "$VALUE" | sed 's/0[xX]//' | bc 2>/dev/null
              ;;

          0*) printf "ibase=8;  %s\b" "$VALUE" | bc 2>/dev/null
              ;;

           *) printf "%s" "$VALUE"
              ;;
    esac
  }


### Analyze the HP-UX kernel parameter settings based on the values from
### the WebSphere MQ Inforamtion Center.  The 'nfile' parameter does not
### apply to HP-UX 11.31 or later.  Make sure the WebSphere MQ additions
### to the HP-UX data conversion files are in place; otherwise alert the
### user to add them again by running 'reset_iconv_table' as root.

  AnalyzeHPUX() {
    IBM_SEMMNI=1024
    IBM_SEMMNS=16384
    IBM_SEMMSL=100
    IBM_SEMMSL_MIN=64
    IBM_SEMMNU=16384
    IBM_SEMUME=256
    IBM_SEMAEM=16384
    IBM_SEMAEM_MIN=1
    IBM_SEMVMX=32767
    IBM_SEMVMX_MIN=1
    IBM_SHMMNI=1024
    IBM_SHMSEG=1024
    IBM_SHMMAX=536870912
    IBM_SHMMAX_MIN=33554432
    IBM_MAXUPRC=1024
    IBM_MAX_THREAD_PROC=66
    IBM_MAXFILES=10000
    IBM_MAXFILES_LIM=10000
    IBM_NFILE=20000
    IBM_MAXDSIZ_MIN=1073741824
    IBM_MAXDSIZ64_MIN=1073741824
    IBM_MAXSSIZ_MIN=8388608
    IBM_MAXSSIZ64_MIN=8388608

    CUR_SHMMNI=`GetHPUXValue shmmni`
    CUR_SHMSEG=`GetHPUXValue shmseg`
    CUR_SHMMAX=`GetHPUXValue shmmax`
    CUR_SEMMNI=`GetHPUXValue semmni`
    CUR_SEMMNS=`GetHPUXValue semmns`
    CUR_SEMMSL=`GetHPUXValue semmsl`
    CUR_SEMMNU=`GetHPUXValue semmnu`
    CUR_SEMUME=`GetHPUXValue semume`
    CUR_SEMAEM=`GetHPUXValue semaem`
    CUR_SEMVMX=`GetHPUXValue semvmx`
    CUR_MAXUPRC=`GetHPUXValue maxuprc`
    CUR_MAX_THREAD_PROC=`GetHPUXValue max_thread_proc`
    CUR_MAXFILES=`GetHPUXValue maxfiles`
    CUR_MAXFILES_LIM=`GetHPUXValue maxfiles_lim`
    CUR_MAXDSIZ=`GetHPUXValue maxdsiz`
    CUR_MAXDSIZ64=`GetHPUXValue maxdsiz_64bit`
    CUR_MAXSSIZ=`GetHPUXValue maxssiz`
    CUR_MAXSSIZ64=`GetHPUXValue maxssiz_64bit`
    CUR_NFILE=`GetHPUXValue nfile`

    printf "\nSystem V Semaphores\n"
    DisplayLimit semmni           sets        "$CUR_SEMMNI"           "$IBM_SEMMNI"           75% 
    DisplayLimit semmns           semaphores  "$CUR_SEMMNS"           "$IBM_SEMMNS"           75%
    DisplayLimit semmsl           semaphores  "$CUR_SEMMSL"           "$IBM_SEMMSL"           "$IBM_SEMMSL_MIN"
    DisplayLimit semmnu           undos       "$CUR_SEMMNU"           "$IBM_SEMMNU"           75%
    DisplayLimit semume           undos       "$CUR_SEMUME"           "$IBM_SEMUME"
    DisplayLimit semaem           units       "$CUR_SEMAEM"           "$IBM_SEMAEM"           "$IBM_SEMAEM_MIN"
    DisplayLimit semvmx           units       "$CUR_SEMVMX"           "$IBM_SEMVMX"           "$IBM_SEMVMX_MIN"

    printf "\nSystem V Shared Memory\n"
    DisplayLimit shmmni           sets        "$CUR_SHMMNI"           "$IBM_SHMMNI"           75%
    DisplayLimit shmmax           bytes       "$CUR_SHMMAX"           "$IBM_SHMMAX"           "$IBM_SHMMAX_MIN"
    DisplayLimit shmseg           sets        "$CUR_SHMSEG"           "$IBM_SHMSEG"           75%

    printf "\nSystem Settings\n"
    DisplayLimit maxuprc          processes   "$CUR_MAXUPRC"          "$IBM_MAXUPRC"          50%
    DisplayLimit max_thread_proc  threads     "$CUR_MAX_THREAD_PROC"  "$IBM_MAX_THREAD_PROC"
    DisplayLimit maxdsiz          bytes       "$CUR_MAXDSIZ"          "$IBM_MAXDSIZ_MIN"      60%
    DisplayLimit maxdsiz_64bit    bytes       "$CUR_MAXDSIZ64"        "$IBM_MAXDSIZ64_MIN"
    DisplayLimit maxssiz          bytes       "$CUR_MAXSSIZ"          "$IBM_MAXSSIZ_MIN"
    DisplayLimit maxssiz_64bit    bytes       "$CUR_MAXSSIZ64"        "$IBM_MAXSSIZ64_MIN"
    DisplayLimit maxfiles         files       "$CUR_MAXFILES"         "$IBM_MAXFILES"         75%
    DisplayLimit maxfiles_lim     files       "$CUR_MAXFILES_LIM"     "$IBM_MAXFILES_LIM"     75%

    if [ $OSREL -lt 31 ]; then
      DisplayLimit nfile          files       "$CUR_NFILE"            "$IBM_NFILE"            75%
    fi

    printf "\nSystem Configuration Files used by WebSphere MQ Data Conversion\n"
    ICONVFAIL=0

    case $ARCH in
      PA-RISC) ICONVFILES="/usr/lib/nls/iconv/config.iconv"
               ;;

      Itanium) ICONVFILES="/usr/lib/nls/iconv/config.iconv"
               ICONVFILES="$ICONVFILES /usr/lib/nls/iconv/hpux32/config.iconv"
               ICONVFILES="$ICONVFILES /usr/lib/nls/iconv/hpux64/config.iconv"
               ;;
    esac

    for ICONVFILE in $ICONVFILES; do
      ICONVSTAT=$FAIL
      grep -q '^#StartMQSeries' $ICONVFILE 2>/dev/null &&
        grep -q '^#EndMQSeries' $ICONVFILE 2>/dev/null && ICONVSTAT=$PASS

      if [ $ICONVSTAT = $PASS ]; then
        printf "  %-53.53s  %-16.16s  %b\n" "$ICONVFILE" "Configured" $PASS
      else
        printf "  %-53.53s  %-16.16s  %b\n" "$ICONVFILE" "Not Configured" $FAIL
        ICONVFAIL=`expr $ICONVFAIL + 1`
      fi
    done

    if [ $ICONVFAIL -gt 0 ]; then
      printf "> Run the WebSphere MQ 'reset_iconv_table' command as root to correct this!\n"
    fi

    CheckShellDefaultOptions
  }


### Most Linux systems today provide the sysctl program for querying the
### value of kernel parameters, but if that is not available they may be
### read from the proc filesystem.  The value string may contain several
### fields, so it is printed as a string for the caller to dissect.

  GetLinuxValue() {
    PARAM=$1
    PPATH=$2
    VALUE=

    if [ -x /sbin/sysctl ]; then
      VALUE=`/sbin/sysctl -n $PARAM 2>/dev/null`
    fi

    if [ -z "$VALUE" -a -n "$PROCPATH" ]; then
      PROC=`mount -t proc 2>/dev/null | awk '{print $3}'`
      if [ -n "$PROC" -a -r "$PROC/$PROCPATH" ]; then
        VALUE=`cat "$PROC/$PROCPATH"`
      fi
    fi

    printf "$VALUE"
  }


### Analyze the Linux kernel parameter settings based on the values from
### the WebSphere MQ Inforamtion Center.  The documentation does list an
### msgmni value, but that is an error and we do not query msgmni here.

  AnalyzeLinux() {
    IBM_SEMMSL=500
    IBM_SEMMNS=256000
    IBM_SEMOPM=250
    IBM_SEMMNI=1024
    IBM_SHMMNI=4096
    IBM_SHMALL=2097152
    IBM_SHMMAX=268435456
    IBM_SHMMAX_MIN=33554432
    IBM_KEEPALIVE=300
    IBM_KEEPALIVE_MAX=600
    IBM_FILEMAX=524288
    IBM_NOFILE_HARD=10240
    IBM_NOFILE_SOFT=10240
    IBM_NPROC_HARD=4096
    IBM_NPROC_SOFT=4096

    CUR_SHMMNI=`GetLinuxValue kernel.shmmni sys/kernel/shmmni`
    CUR_SHMALL=`GetLinuxValue kernel.shmall sys/kernel/shmall`
    CUR_SHMMAX=`GetLinuxValue kernel.shmmax sys/kernel/shmmax`
    CUR_SEM=`GetLinuxValue kernel.sem sys/kernel/sem`
    CUR_SEMMSL=`printf "%s" "$CUR_SEM" | awk '{print $1}'`
    CUR_SEMMNS=`printf "%s" "$CUR_SEM" | awk '{print $2}'`
    CUR_SEMOPM=`printf "%s" "$CUR_SEM" | awk '{print $3}'`
    CUR_SEMMNI=`printf "%s" "$CUR_SEM" | awk '{print $4}'`
    CUR_FILEMAX=`GetLinuxValue fs.file-max sys/fs/file-max`
    CUR_KEEPALIVE=`GetLinuxValue net.ipv4.tcp_keepalive_time`
    CUR_NOFILE_HARD=`ulimit -Hn 2>/dev/null`
    CUR_NOFILE_SOFT=`ulimit -Sn 2>/dev/null`
    CUR_NPROC_HARD=`ulimit -Hu 2>/dev/null`
    CUR_NPROC_SOFT=`ulimit -Su 2>/dev/null`

    printf "\nSystem V Semaphores\n"
    DisplayLimit "semmsl     (sem:1)"  semaphores  "$CUR_SEMMSL"       "$IBM_SEMMSL"
    DisplayLimit "semmns     (sem:2)"  semaphores  "$CUR_SEMMNS"       "$IBM_SEMMNS"       75%
    DisplayLimit "semopm     (sem:3)"  operations  "$CUR_SEMOPM"       "$IBM_SEMOPM"
    DisplayLimit "semmni     (sem:4)"  sets        "$CUR_SEMMNI"       "$IBM_SEMMNI"       75%

    printf "\nSystem V Shared Memory\n"
    DisplayLimit shmmax                bytes       "$CUR_SHMMAX"       "$IBM_SHMMAX"       "$IBM_SHMMAX_MIN"
    DisplayLimit shmmni                sets        "$CUR_SHMMNI"       "$IBM_SHMMNI"       75%
    DisplayLimit shmall                pages       "$CUR_SHMALL"       "$IBM_SHMALL"       50%

    printf "\nSystem Settings\n"
    DisplayLimit file-max              files       "$CUR_FILEMAX"      "$IBM_FILEMAX"      75%
    DisplayLimit tcp_keepalive_time    seconds     "$CUR_KEEPALIVE"    "$IBM_KEEPALIVE"    "$IBM_KEEPALIVE_MAX"

    printf "\nCurrent User Limits (%s)\n" "`id -un 2>/dev/null`"
    DisplayLimit "nofile       (-Hn)"  files       "$CUR_NOFILE_HARD"  "$IBM_NOFILE_HARD"  75%
    DisplayLimit "nofile       (-Sn)"  files       "$CUR_NOFILE_SOFT"  "$IBM_NOFILE_SOFT"  75%
    DisplayLimit "nproc        (-Hu)"  processes   "$CUR_NPROC_HARD"   "$IBM_NPROC_HARD"   75%
    DisplayLimit "nproc        (-Su)"  processes   "$CUR_NPROC_SOFT"   "$IBM_NPROC_SOFT"   75%

    CheckShellDefaultOptions
  }


### Determine the value of a Solaris 9 kernel parameter using the sysdef
### output which was gathered earlier, for performance reasons.

  GetSolarisV9Value() {
    PARAM=$1

    printf "%s" "$CUR_SYSDEF" | grep "($PARAM)" | awk '{print $1}'
  }


### Analyze Solaris 9 kernel parameter settings based on the values from
### the WebSphere MQ documentation.  WebSphere MQ 7.1 and later requires
### Solaris 10 or later.

  AnalyzeSolarisV9() {
    IBM_SEMMNI=1024
    IBM_SEMMNS=16384
    IBM_SEMMSL=100
    IBM_SEMMSL_MIN=64
    IBM_SEMMNU=16384
    IBM_SEMUME=256
    IBM_SEMAEM=16384
    IBM_SEMAEM_MIN=1
    IBM_SEMVMX=32767
    IBM_SEMVMX_MIN=1
    IBM_SEMOPM=100
    IBM_SEMOPM_MIN=5
    IBM_SEMMAP=`expr $IBM_SEMMNI + 2`
    IBM_SHMMNI=1024
    IBM_SHMSEG=1024
    IBM_SHMMAX=4294967295
    IBM_SHMMAX_MIN=33554432
    IBM_SHMMIN=1
    IBM_SHMMIN_MAX=1000
    IBM_MAXUPRC=1024
    IBM_FD_CUR=10000
    IBM_FD_MAX=10000

    CUR_SYSDEF=`/usr/sbin/sysdef -i 2>/dev/null`
    CUR_SHMMNI=`GetSolarisV9Value SHMMNI`
    CUR_SHMSEG=`GetSolarisV9Value SHMSEG`
    CUR_SHMMAX=`GetSolarisV9Value SHMMAX`
    CUR_SHMMIN=`GetSolarisV9Value SHMMIN`
    CUR_SEMMNI=`GetSolarisV9Value SEMMNI`
    CUR_SEMMNS=`GetSolarisV9Value SEMMNS`
    CUR_SEMMSL=`GetSolarisV9Value SEMMSL`
    CUR_SEMMNU=`GetSolarisV9Value SEMMNU`
    CUR_SEMUME=`GetSolarisV9Value SEMUME`
    CUR_SEMAEM=`GetSolarisV9Value SEMAEM`
    CUR_SEMVMX=`GetSolarisV9Value SEMVMX`
    CUR_SEMOPM=`GetSolarisV9Value SEMOPM`
    CUR_MAXUPRC=`GetSolarisV9Value v.v_maxup`
    CUR_FD_CUR=`ulimit -Sn 2>/dev/null`
    CUR_FD_MAX=`ulimit -Hn 2>/dev/null`

    printf "\nSystem V Semaphores\n"
    DisplayLimit SEMMNI                sets         "$CUR_SEMMNI"          "$IBM_SEMMNI"  75%
    DisplayLimit SEMMNS                semaphores   "$CUR_SEMMNS"          "$IBM_SEMMNS"  75%
    DisplayLimit SEMMSL                semaphores   "$CUR_SEMMSL"          "$IBM_SEMMSL"  "$IBM_SEMMSL_MIN"
    DisplayLimit SEMMNU                undos        "$CUR_SEMMNU"          "$IBM_SEMMNU"  75%
    DisplayLimit SEMUME                undos        "$CUR_SEMUME"          "$IBM_SEMUME"
    DisplayLimit SEMAEM                units        "$CUR_SEMAEM"          "$IBM_SEMAEM"  "$IBM_SEMAEM_MIN"
    DisplayLimit SEMVMX                units        "$CUR_SEMVMX"          "$IBM_SEMVMX"  "$IBM_SEMVMX_MIN"
    DisplayLimit SEMOPM                operations   "$CUR_SEMOPM"          "$IBM_SEMOPM"  "$IBM_SEMOPM_MIN"

    printf "\nSystem V Shared Memory\n"
    DisplayLimit SHMMNI                sets         "$CUR_SHMMNI"          "$IBM_SHMMNI"  75%
    DisplayLimit SHMMAX                bytes        "$CUR_SHMMAX"          "$IBM_SHMMAX"  "$IBM_SHMMAX_MIN"
    DisplayLimit SHMSEG                sets         "$CUR_SHMSEG"          "$IBM_SHMSEG"
    DisplayLimit SHMMIN                bytes        "$CUR_SHMMIN"          "$IBM_SHMMIN"  "$IBM_SHMMIN_MAX"

    printf "\nSystem Settings\n"
    DisplayLimit maxuprc               processes    "$CUR_MAXUPRC"         "$IBM_MAXUPRC" 50%

    printf "\nCurrent User Limits (%s)\n" "`id -un 2>/dev/null`"
    DisplayLimit "rlim_fd_max  (-Hn)"  descriptors  "${CUR_FD_MAX:=1024}"  "$IBM_FD_MAX"  75%
    DisplayLimit "rlim_fd_cur  (-Sn)"  descriptors  "${CUR_FD_CUR:=256}"   "$IBM_FD_CUR"  75%

    CheckShellDefaultOptions
  }


### In Solaris 10 and later, resource limits are managed using projects.
### Since the prctl command can't show limits of an inactive project use
### the projects command to query the project settings.  Fill in Solaris
### default values for any limit that is not explicitly set.

  GetSolarisValue() {
    PARAM=$1

    VALUE=`projects -l $PROJECT | grep "${PARAM}=" | sed 's/^.*=//' |
           env LANG=C tr ',' ' ' | awk '{print $2}'`

    if [ -z "$VALUE" ]; then
      case $PARAM in
        process.max-file-descriptor) VALUE=256
                                     ;;

                project.max-shm-ids) VALUE=128
                                     ;;

             project.max-shm-memory) VALUE=`/usr/sbin/prtconf |
                                       grep '^Memory size:' |
                                       sed -e 's/Megabytes/\* 1048576/' \
                                           -e 's/Gigabytes/\* 1073741824/' \
                                           -e 's/Terabytes/\* 1099511627776/' \
                                           -e 's/.*://' -e 's/$/ \/ 4/' | bc 2>/dev/null`
                                     ;;

                project.max-sem-ids) VALUE=128
                                     ;;
      esac
    fi

    printf "$VALUE"
  }


### Analyze Solaris project settings baseed on the recommended values in
### the WebSphere MQ documentation.  The user should provide one or more
### projects to analyze, but if not, analyze any project with one of the
### main WebSphere MQ queue manager processes (amqzxma0 or amqzmgr0, the 
### execution controller and service manager, respectively) and also the
### group.mqm project, if it exists.  Issue warnings when queue managers
### are found outside the group.mqm project or when no group.mqm project
### is found.  When all else fails, analyze the current project.

  AnalyzeSolaris() {
    if [ -z "$PROJLIST" ]; then
      PROJLIST=`ps -eo project,args | grep -E '[a]mqzxma0|[a]mqzmgr0' |
                awk '{print $1}' | uniq | grep -vw group\.mqm | tr '\n' ' '`
      COMMALIST="(`printf \"%s\n\" \"$PROJLIST\" | Trim | sed 's/ /, /g'`)"
      printf "\n"

      if projects -l group.mqm 1>/dev/null 2>&1; then
        if [ -n "$PROJLIST" ]; then
          Message 1014 "$COMMALIST"
          Message 1008 "group.mqm and other projects with queue manager activity $COMMALIST"
          PROJLIST="group.mqm $PROJLIST"
        else
          Message 1008 "the group.mqm project"
          PROJLIST="group.mqm"
        fi
      else
        Message 1015

        if [ -n "$PROJLIST" ]; then
          Message 1008 "all projects with queue manager activity $COMMALIST"
        else
          Message 1008 "the current project"
          PROJLIST=`id -p | sed -e 's/^.*projid=.*(//' -e 's/).*//'`
        fi
      fi
    fi


    IBM_SEMMNI=1024
    IBM_SHMMNI=1024
    IBM_SHMMAX=4294967296
    IBM_SHMMAX_MIN=4294967295
    IBM_MAXFDS=10000

    for PROJECT in ${PROJLIST:=default} ; do
      PROJID=`projects -l group.mqm 2>/dev/null | grep projid | sed 's/.*: *//'` || {
        Error 1007 $PROJECT
        continue
      }

      CUR_SHMMNI=`GetSolarisValue project.max-shm-ids`
      CUR_SHMMAX=`GetSolarisValue project.max-shm-memory`
      CUR_SEMMNI=`GetSolarisValue project.max-sem-ids`
      CUR_MAXFDS=`GetSolarisValue process.max-file-descriptor`

      printf "\nProject %s (%s): System V Semaphores\n" "$PROJECT" "$PROJID"
      DisplayLimit max-sem-ids          sets         "$CUR_SEMMNI"  "$IBM_SEMMNI"  75%

      printf "\nProject %s (%s): System V Shared Memory\n" "$PROJECT" "$PROJID"
      DisplayLimit max-shm-ids          sets         "$CUR_SHMMNI"  "$IBM_SHMMNI"  75%
      DisplayLimit max-shm-memory       bytes        "$CUR_SHMMAX"  "$IBM_SHMMAX"  "$IBM_SHMMAX_MIN"

      printf "\nProject %s (%s): Other Settings\n" "$PROJECT" "$PROJID"
      DisplayLimit max-file-descriptor  descriptors  "$CUR_MAXFDS"  "$IBM_MAXFDS"  75%
      printf "\n"
    done

    CheckShellDefaultOptions
  }


### Initialize variables, counters, and constants used by the script and
### tweak the syntax on Solaris 10 and later systems which use projects.

  unset PROJLIST MQVER OSVER OPSYS ARCH

  WARNINGS=0
  FAILURES=0

  if [ -t 1 ]; then
    PASS="\033[32mPASS\033[m"
    WARN="\033[33mWARN\033[m"
    FAIL="\033[31mFAIL\033[m"
  else
    PASS=PASS
    WARN=WARN
    FAIL=FAIL
  fi

  UNLIMITED=unlimited
  LITERAL=literal
  UNKNOWN="???"
  AUTO=auto

  OPTSTR=":v:"

  case `uname -s` in
    HP-UX) OPSYS=HPUX
           ;;

    SunOS) case `uname -r` in
             5.9) OPSYS=SolarisV9
                  ;;

               *) OPSYS=Solaris
                  OPTSTR="${OPTSTR}p:"
                  ;;
           esac
           ;;

        *) OPSYS=`uname -s`
           ;;
  esac


### Parse the command line to determine the WebSphere MQ version, and on
### Solaris 10 and later the project name(s) to analyze.  Issue an error
### if there are dangling arguments or no valid WebSphere MQ version was
### given, but be flexible in allowing different version formats.  Point
### WebSphere MQ 6.0 and 5.3 users to the mqconfig-old script.

  while getopts $OPTSTR OPT ; do
    case $OPT in
      \:) Error 1000 "$OPTARG" && PrintSyntax && exit 1
          ;;

      \?) if [ "${OPTARG:-?}" = "?" ]; then
            PrintHelp && exit 0
          else
            Error 1001 $OPTARG && PrintSyntax && exit 1
          fi
          ;;

       p) if [ "${PROJLIST:=$OPTARG}" != "$OPTARG" ]; then
            PROJLIST="$PROJLIST $OPTARG"
          fi
          ;;

       v) if [ "${MQVER:=$OPTARG}" != "$OPTARG" ]; then
            PrintSyntax && exit 1
          fi
          ;;
    esac
  done

  if [ $OPTIND -le $# ]; then
    shift `expr $OPTIND - 1`
    Error 1004 "$@" && exit 1
  fi

  MQVER=`printf "%s\n" "$MQVER" | tr -d 'vV' | Trim`

  if [ -z "$MQVER" ]; then
    Error 1002 && PrintSyntax && exit 1
  fi

  case $MQVER in
      75*|7.5*) MQVER=7.5
                ;;

      71*|7.1*) MQVER=7.1
                ;;

    7|70*|7.0*) MQVER=7.0
                ;;

    6|60*|6.0*) Error 1011 6.0 && exit 1
                ;;

      53*|5.3*) Error 1011 5.3 && exit 1
                ;;

      52*|5.2*) Error 1003 5.2 && exit 1
                ;;

      51*|5.1*) Error 1003 5.1 && exit 1
                ;;

    5|50*|5.0*) Error 1003 5.0 && exit 1
                ;;

            2*) Error 1003 2 && exit 1
                ;;

            1*) Error 1003 1 && exit 1
                ;;

             *) Error 1009 $MQVER && PrintSyntax && exit 1
                ;;
  esac


### Determine the operating system name and version as these will affect
### how the kernel is tuned.  On Linux we list the distribution name but
### do not otherwise check it, but on other platforms we do validate the
### operating system.  On HP-UX we verify that the hardware is supported
### (see /usr/include/sys/unistd.h) because WebSphere MQ dropped support
### for PA-RISC hardware in WebSphere MQ 7.1.  On AIX we avoid 'oslevel'
### when possible since it is quite slow.  We query the technology level
### from the bos.mp64 version and avoid checking the service pack except
### on AIX 5.3 where the WebSphere MQ V7.0 SOE requires us to do so.

  case `uname -s` in
       AIX) OSVER=`uname -v`
            OSREL=`uname -r`
            ARCH=`uname -p`
            TL=`lslpp -qcL bos.mp64 2>/dev/null | awk -F: '{print $3}' | awk -F. '{print $3}'`

            case $MQVER:$OSVER.$OSREL in
              7.[015]:7.1) ;;

               7.[15]:6.1) if [ $TL -lt 5 ]; then
                             Error 1013 $MQVER && exit 1
                           fi
                           ;;

                  7.0:6.1) ;;

                  7.0:5.3) SP=`oslevel -s | awk -F- '{print $3}'`

                           if [ $TL -lt 4 ]; then
                             Error 1012 && exit 1
                           elif [ $TL -eq 5 -a $SP -lt 2 ]; then
                             Error 1012 && exit 1
                           elif [ $TL -eq 7 -a $SP -lt 1 ]; then
                             Error 1012 && exit 1
                           fi
                           ;;

                        *) Error 1010 $MQVER AIX $OSVER.$OSREL && exit 1
                           ;;
            esac

            Message 1005 "AIX $OSVER.$OSREL TL$TL ($ARCH)" $MQVER
            ;;

     HP-UX) OSVER=`uname -r | sed -e 's/B\.//' -e 's/\..*//'`
            OSREL=`uname -r | sed 's/.*\.//'`

            CPUVER=`getconf CPU_VERSION 2>/dev/null`

            if [ ${CPUVER:=0} -eq 523 ]; then
              ARCH=PA-RISC
            elif [ $CPUVER -ge 524 -a $CPUVER -le 526 ]; then
              ARCH="Motorola 680x0"
            elif [ $CPUVER -ge 528 -a $CPUVER -le 767 ]; then
              ARCH=PA-RISC
            elif [ $CPUVER -ge 768 ]; then
              ARCH=Itanium
            else
              ARCH=Unknown
            fi

            case $MQVER:$ARCH in
                *:Itanium) ;;

              7.0:PA-RISC) ;;

                        *) Error 1010 $MQVER $ARCH hardware && exit 1
                           ;;
            esac

            case $MQVER:$OSVER in
              7.[15]:11) if [ $OSREL -lt 31 ]; then
                           Error 1010 $MQVER HP-UX $OSVER.$OSREL && exit 1
                         fi
                         ;;

                 7.0:11) if [ $OSREL -lt 23 ]; then
                           Error 1010 $MQVER HP-UX $OSVER.$OSREL && exit 1
                         fi
                         ;;

                      *) Error 1010 $MQVER HP-UX $OSVER.$OSREL && exit 1
                         ;;
            esac

            Message 1005 "HP-UX $OSVER.$OSREL ($ARCH)" "$MQVER"
            ;;

     Linux) OSVER=`uname -r`
            ARCH=`uname -p`

            if [ -x /usr/bin/lsb_release ]; then
              DIST=`/usr/bin/lsb_release -sd 2>/dev/null | env LANG=C tr -d \"`
            elif [ -r /etc/redhat-release ]; then
              DIST=`head -1 /etc/redhat-release 2>/dev/null`
            elif [ -r /etc/SuSE-release ]; then
              DIST=`head -1 /etc/SuSE-release 2>/dev/null`
            elif [ -r /etc/UnitedLinux-release ]; then
              DIST=`head -1 /etc/UnitedLinux-release 2>/dev/null`
            else
              DIST=`cat /etc/*-release 2>/dev/null | head -1`
            fi

            Message 1005 "${DIST:=Unknown Linux ($ARCH, $OSVER)}" "$MQVER"
            ;;

     SunOS) OSVER=`uname -r | sed 's/.*\.//'`
            ARCH=`uname -p`
            PATH=$PATH:/usr/xpg6/bin:/usr/xpg4/bin:$PATH:/usr/ucb

            case $MQVER:$OSVER in
              7.[015]:1[01]) ;;

                      7.0:9) if [ $ARCH != sparc ]; then
                               Error 1010 $MQVER $ARCH hardware && exit 1
                             fi
                             ;;

                          *) Error 1010 $MQVER Solaris $OSVER && exit 1
                             ;;
            esac

            Message 1005 "Solaris $OSVER ($ARCH)" "$MQVER"
            ;;

    Darwin) Error 1006 "OS X" && exit 1
            ;;

         *) Error 1006 `uname -s` && exit 1
            ;;
  esac


### Make sure the binary calculator (bc) is installed before proceeding.
### We rely on bc to handle arithmetic and comparisons since some of the
### values we check can overflow arithmetic precision of the shell.

  printf "quit\n" | bc 1>/dev/null 2>&1  || {
    Error 1016 bc && exit 1
  }


### Call the appropriate function to analyze each operating system.  Set
### the exit status based on the number of failures and warnings.

  eval Analyze$OPSYS

  if [ ${FAILURES:=0} -gt 0 ]; then
    exit 2
  elif [ ${WARNINGS:=0} -gt 0 ]; then
    exit 1
  else
    exit 0
  fi

