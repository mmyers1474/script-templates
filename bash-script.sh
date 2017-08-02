#!/bin/bash
#===============================================================================
#  HEADER
#==============================================================================
#  IMPLEMENTATION
#% name         bash_template
#% title		Bash Shell Template
#% version      0.0.1
#% checksum		5926ed74eb9baf0dc74b08e2e9be26a0
#% author       Matthew Myers
#% copyright	Copyright (c) http://www.metatechlabs.com
#% license      GNU General Public License
#
#===============================================================================
#  SYNOPSIS
#?   ${scriptname} [-hv] [-o[file]] args ...
#?
#? DESCRIPTION
#?    This is a script template
#?    to start any good shell script.
#?
#? OPTIONS
#?    -o [file], --output=[file]    Set log file (default=/dev/null)
#?                                  use DEFAULT keyword to autoname file
#?                                  The default value is /dev/null.
#?    -t, --timelog                 Add timestamp to log ("+%y/%m/%d@%H:%M:%S")
#?    -x, --ignorelock              Ignore if lock file exists
#?    -h, --help                    Print this help
#?    -v, --version                 Print script information
#?
#? EXAMPLES
#?    ${scriptname} -o DEFAULT arg1 arg2
#
#===============================================================================
#  OPTIONS
#  This section has several options you can select form that control the behavior
#  of the script at runtime.  DO NOT UNCOMMENT ANYTHING.  Just set the value and
#  the script parses the section below without taking up additonal memory or variables.
#
#  Option 				Validation Regexp		Description
#& runas=				# username				Specify a user you want to impose this script being run as.
#& runtimelock=no		#(yes|no)				Use RUNLOCKING to prevent multiple instances.
#& outputto=screen		#(screen|logfile|both)	Send ouptput to the screen, a log file, or both.
#& minargcount=0		# N						Specify the minimum allowed command line arguments.
#& errortrapping=yes	#(yes|no)				Using built-in error handling or not.
#===============================================================================
#  HISTORY
#@  
#===============================================================================
# END_OF_HEADER
#===============================================================================
# - Declarations ---------------------------------------------------------------
# -- Properties: Internal ----------------------------------------------------------------
# --- Script Use ---------------------------------------------------------------

# --- Interal Use --------------------------------------------------------------
readonly __scripthome="$( cd $( dirname ${BASH_SOURCE[0]} ) && pwd )"
readonly __scriptname="$(basename ${0})"
readonly __scriptbase="${__scriptname%.*}"
readonly __this="${__scripthome}/${__scriptname}"
__name=$(sed -n 's/^#%[ \t]\+name[ \t]\+//gp' "${__this}")
__title=$(sed -n 's/^#%[ \t]\+title[ \t]\+//gp' "${__this}")
__version=$(sed -n 's/^#%[ \t]\+version[ \t]\+//gp' "${__this}")
__checksum=$(sed -n 's/^#%[ \t]\+checksum[ \t]\+//gp' "${__this}")
__about=$(sed -n 's/^#% //gp' "${__this}")
__usage=$(sed -n 's/^#? //gp' "${__this}")

# -- Constants -----------------------------------------------------------------
readonly DEBUG=$(echo "${DEBUG}")


# -- Variables -----------------------------------------------------------------
declare -A color
declare PIDFILE="${__scripthome}/${__scriptbase}.pid"
declare LOGFILE="${__scripthome}/${__scriptbase}.log"


# -- Functions -----------------------------------------------------------------
# --- Debugging Output ---------------------------------------------------------
# A simple colorized debugging output function.  If the DEBUG environment variable
# is set then any statements using the debug function call will be output to the 
# screen with colorization via the colorized echo function defined above.
function debug() {
  if [[ ${DEBUG} ]]
  then
    in="$*"
	buffer="${in//\]/\]\}}"
	in="${buffer}"
	buffer="${in//\[/\$\{color\[}"
	out="${buffer}"
	eval echo -e "${out}"
  fi
}

# --- Colorized echo -----------------------------------------------------------
# Colorized echo with simplistic implementation
# Use a single letter enclosed in square brackets to indicate which color you want.
function cecho() {
  in="$*"
  buffer="${in//\]/\]\}}"
  in="${buffer}"
  buffer="${in//\[/\$\{color\[}"
  out="${buffer}"
  eval echo -e "${out}"
}

function __errortrap() {
  local lineno="$1"
  local message="$2"
  local code="${3:-1}"
  
  if [[ -n "${message}" ]]
  then
	cecho "[C]${__scriptname}: [R]FATAL ERROR[n] at [G]$(date +'%r')[n] on or near line [B]${LINENO}[n].\nThe returned message was: [M]${ECODE}[n]." 2>&1
  else
	cecho "[C]${__scriptname}: [R]FATAL ERROR[n] at [G]$(date +'%r')[n] on or near line [B]${LINENO}[n].\nThe return code was: [M]${ECODE}[n]." 2>&1
  fi
  exit "${code}"
}
function __assign_colors() {
  color=(
    [n]='\033[0m'    # Text Reset
    [k]='\033[0;30m'      # Black
    [r]='\033[0;31m'        # Red
    [g]='\033[0;32m'      # Green
    [y]='\033[0;33m'     # Yellow
    [b]='\033[0;34m'       # Blue
    [p]='\033[0;35m'     # Purple
    [c]='\033[0;36m'       # Cyan
    [w]='\033[0;37m'      # White
    [K]='\033[0;90m'      # Black
    [R]='\033[0;91m'        # Red
    [G]='\033[0;92m'      # Green
    [Y]='\033[0;93m'     # Yellow
    [B]='\033[0;94m'       # Blue
    [P]='\033[0;95m'     # Purple
    [C]='\033[0;96m'       # Cyan
    [W]='\033[0;97m'      # White
  )
}
function __update() {
  IFS='.' read major minor rev <<< "${__version}"
  debug "Major:  ${major} Minor:  ${minor} Revision:  ${rev}"
  rev=$((rev+1))
  if [[ "${rev}" -gt 99 ]]
  then
	rev=0
	((minor++))
	if [[ "${minor}" -gt 9 ]]
	then
		((major++))
	fi
  fi
  __xx__="${major}.${minor}.${rev}"
  debug "version = ${__xx__}"
  
  cmd="sed -i" 
  regexp="s/^\\(#%[ \\t]\\+version[ \\t]\\+\\)[0-9.]\\+/\\1${__xx__}/g"
  echo "sed -i '${regexp}' ${script}"  > "./update.sh"

  __xx__=$(md5sum "${__this}" | awk '{ print $1 }')
  debug "checksum = ${__xx__}"
  regexp="s/^\\(#%[ \\t]\\+checksum[ \\t]\\+\\)[a-zA-Z0-9]\\+/\\1${__xx__}/g"
  (sleep 2; sed -i '${regexp}' "${__this}" &)
  exit
}
function __initialize() {
  set -e				# exit immediate if an error occurs in a pipeline
  set -u				#
  set -o pipefail		# trace ERR through pipes.
  set -o errtrace		# trace ERR through 'time command' and other functions.
  set -o errexit
  set -o nounset
  set -o noclobber
  # set -x  			# Uncomment to debug this shell script.
  # set -n  			# Uncomment to check your syntax, without execution.

  __assign_colors
  
  if [[ ${DEBUG} ]]
  then
    debug "[G]DEBUGGING output enabled![n]"
  fi

  # Verify the script checksum before going too far.
  saved="${__checksum}"
  actual=$(md5sum "${__this}" | awk '{ print $1 }')
  debug "Saved checksum:  ${saved}"
  debug "Actual checksum:  ${actual}"
  echo
  if [[ "${actual}" != "${saved}" ]]
  then
    cecho "[R]The checksum for this script has changed.[n]\\nSaved:${saved}\\nActual:${actual}\\n\\nIf you have not modified this script recently check the scripts contents before running, it may be altered and harmful.\\n"
    echo -n "Do you wish to continue with the execution of this potentialy compromised script? [Y/N] "
    read -n1 yorn
    echo
    if [[ "${yorn,,}" == "n" ]]
    then
      exit 127
    fi
  fi
  
  runas=$(sed -ne "s/#& runas=//gp" "${__this}" | sed -ne "s/#.*//gp" | xargs)
  if [[ -n "${runas}" ]]; then
    # Verify we are running as the service account user, if not re-execute the script as as the service account user.
    if [[ "$(id -un)" != "${runas}" ]]; then
      echo "Reloading this script as the user ${runas}"
      sudo -u "${runas}" "${scriptdir}/${scriptname}" $@
      exit 0
    fi
  fi
  
  runtimelock=$(sed -ne "s/^#& runtimelock=//gp" "${__this}" | sed -ne "s/#.*//gp" | xargs)
  if [[ "${runtimelock,,}" == "yes" ]]; then
    if [[ -f "${PIDFILE}" ]]; then
	  PID=$(cat "${PIDFILE}")
      echo "${__scriptname} is already running with process ID ${PID}."
      exit
    fi
    echo "$$" > "${PIDFILE}"
  fi

  outputto=$(sed -ne "s/^#& outputto=//gp" "${__this}" | sed -ne "s/#.*//gp" | xargs)
  case "${outputtype,,}" in
   'screen')
     debug "Sending all output to the screen only."
   ;;
   'logfile')
     debug "Sending all output to ${LOGFILE} only."
     exec > "${LOGFILE}"
     exec 2>&1
   ;;
   'both')
     debug "Sending all output to your screen and to ${LOGFILE}."
  #   exec > "${LOGFILE}"
     exec 2>&1 | tee -a "${LOGFILE}"
   ;;
  esac
  
  errortrapping=$(sed -ne "s/^#& errortrapping=//gp" "${__this}" | sed -ne "s/#.*//gp" | xargs)
  if [[ "${errortrapping,,}" == "yes" ]]
  then
  	trap 'errortrap' ERR INT QUIT TERM
  fi
  trap '[[ -f "${PIDFILE}" ]] && rm -f "${PIDFILE}"; ' EXIT

  minargcount=$(sed -ne "s/#& minargcount=//gp" "${__this}" | sed -ne "s/#.*//gp" | xargs)
  if [[ $# -lt ${minargcount} ]] ; then
      echo "${__usage}"
      exit 1;
  fi
}
__initialize $@

# -- CLI Option Processing --------------------------------------------------

while getopts ":hAV" optname
do
 case "$optname" in
   "h")
  echo "${__USAGE__}"
  exit 0;
  ;;
   "A") 
  echo "${__ABOUT__}"
  exit 0;
  ;;
   "V")
  echo "Version ${__VERSION__}"
  exit 0;
  ;;
   "?")
  echo "Unknown option ${OPTARG}"
  exit 0;
  ;;
   ":")
  echo "No argument value for option ${OPTARG}"
  exit 0;
  ;;
   *)
  echo "Unknown error while processing options"
  exit 0;
  ;;
 esac
done

shift $(($OPTIND - 1))

# ------------------------------------------------------------------------------
#  SCRIPT LOGIC GOES HERE
# ------------------------------------------------------------------------------
echo "Hello World"