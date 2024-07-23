#!/command/with-contenv bash
set -e
set -o pipefail

QBT_PID="$(s6-svstat -o pid /run/service/start-qbittorrent)"

if [ "${NICE}" == "skip" ]; then
	echo "Skipped setting nice"
else
	NICE=${NICE:-10}
	renice -n "${NICE}" -p "${QBT_PID}"
    echo "nice -n ${NICE}"
fi

if [ "${IONICE_CLASS}" == "skip" ]; then
	echo "Skipped setting ionice"
else
	IONICE_CLASS=${IONICE_CLASS:-idle}
	ionice -c "${IONICE_CLASS}" -p "${QBT_PID}"
    echo "ionice -c ${IONICE_CLASS}"
fi
