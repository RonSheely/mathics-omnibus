#!/bin/bash
# This is the docker entry point and gets installed as /usr/local/bin/mathics.sh

DJANGO_DOC_HTML_DATA_PATH="/usr/local/lib/python3.8/dist-packages/mathics_django/doc/doc_html_data.pcl"
MATHICS_DJANGO_SYSTEM_DB_PATH="/usr/src/app/.local/var/mathics/mathics.sqlite"

export PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/src/app/.local/bin

script_cmd="${ENTRYPOINT_COMMAND:-$(basename $0)}"

function help {
    cat <<EOF

Usage:
    $script_cmd [arg] [-- params, ...]

Arg:

    -h | --help               Print this help and exit

    --pythonpath              This will be added to PYTHONPATH. Example use-case - absolute path to
                              basedir of mathics source code inside container, ie:
                                 mathics src = /usr/src/app/mathics
                                 --pythonpath /usr/src/app

    -m | --mode {cli|ui|gui|minimal|pdf|copy}
                              Start mathics in either:
                                 * web-ui mode (ui or gui),
                                 * cli mode (cli) or minimal.
								 * viewing manual (pdf) or document
								 * copy the manual mathics.pdf to the host computer
                              Default is cli.
                              See: https://github.com/Mathics3/mathics-core/wiki/Installing#running-mathics

Params:

    Everything passed after '--' will be passed to mathics as is.

EOF
}

mathics_mode=cli
COPY_DOC=0

while (( $# )) ; do
    case "$1" in
        -h | --help)  help ; exit ;;
        -m | --mode)
			mathics_mode="$2"
			shift 2
			;;
        --pythonpath) export PYTHONPATH="$2":$PYTHONPATH ; shift 2 ;;
        --)           shift ; break ;;
        *)            echo "Can't parse '$@'. See '$0 --help'" ; exit 1 ;;
    esac
done

case $mathics_mode in
    cli) mathicsscript $@
		 ;;
    minimal|mathics)
		mathics $@
		;;
    document|pdf)
		evince /usr/src/app/mathics-core/mathics/doc/tex/mathics.pdf
		;;
    copy)
		echo "Copying mathics.pdf to host-attached filesystem."
		cp /usr/src/app/mathics-core/mathics/doc/tex/mathics.pdf /usr/src/app/data/mathics.pdf
		;;
    ui|gui)
	echo
	echo "~~~~ app/data has been mounted to $MATHICS_HOME/data ~~~~"
	if [[ -n $MATHICS_DJANGO_DB_PATH ]]; then
	    echo "~~~~ SQLite data (worksheets, user info) will be stored in $MATHICS_DJANGO_DB_PATH ~~~~"
		if [[ ! -s $MATHICS_DJANGO_DB_PATH ]] && [[ -n $MATHICS_DJANGO_SYSTEM_DB_PATH ]]; then
			echo "~~~~ Copying internal SQLite data (worksheets, user info) to location specified in \$MATHICS_DJANGO_DB_PATH"
			cp -vp $MATHICS_DJANGO_SYSTEM_DB_PATH $MATHICS_DJANGO_DB_PATH
		fi
	else
	    echo "~~~~ SQLite data (worksheets, user info) will be stored in $MATHICS_HOME/data/mathics.sqlite"
	fi
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo
	/usr/bin/mathicsserver -e $@ ;;
    shell)  /bin/bash ;;
    *)   echo "unknown mathics_mode=$mathics_mode. See '$script_cmd --help'" ; exit 2 ;;
esac
