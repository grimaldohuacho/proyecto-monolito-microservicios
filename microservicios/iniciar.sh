#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE="microservicios"
APPS=("usuarios-app" "productos-app" "pedidos-app")
SERVICES=("usuarios-service" "productos-service" "pedidos-service")
LOCAL_PORTS=(3101 3102 3103)
TARGET_PORTS=(3001 3002 3003)

stop_forwarders() {
    pkill -f "kubectl port-forward" 2>/dev/null || true
    for service in "${SERVICES[@]}"; do
        rm -f "/tmp/minikube-${service}-port-forward.pid" "/tmp/${service}-port-forward.log"
    done
}

case "${1:-start}" in
    start)
        ;;
    stop)
        stop_forwarders
        if minikube status >/dev/null 2>&1; then
            minikube stop
        else
            echo "Minikube ya estaba detenido."
        fi
        exit 0
        ;;
    *)
        echo "Uso: $0 [start|stop]"
        exit 2
        ;;
esac

command -v minikube >/dev/null || { echo "Error: falta instalar Minikube."; exit 1; }
command -v kubectl >/dev/null || { echo "Error: falta instalar kubectl."; exit 1; }

stop_forwarders

if minikube status >/dev/null 2>&1; then
    echo "Minikube ya está iniciado."
else
    minikube start --driver=docker
fi

kubectl get namespace "$NAMESPACE" >/dev/null

if ! kubectl wait --for=condition=Ready pod --all -n "$NAMESPACE" --timeout=180s; then
    echo "Error: hay pods que no están listos."
    exit 1
fi

for i in "${!SERVICES[@]}"; do
    app="${APPS[$i]}"
    svc="${SERVICES[$i]}"
    lport="${LOCAL_PORTS[$i]}"
    tport="${TARGET_PORTS[$i]}"

    pod_name=$(kubectl get pod -n "$NAMESPACE" -l "app=$app" -o jsonpath='{.items[0].metadata.name}')
    nohup kubectl port-forward -n "$NAMESPACE" "pod/$pod_name" "${lport}:${tport}" >"/tmp/${svc}-port-forward.log" 2>&1 &
    echo "$!" >"/tmp/minikube-${svc}-port-forward.pid"
done

sleep 3

for i in "${!SERVICES[@]}"; do
    svc="${SERVICES[$i]}"
    port="${LOCAL_PORTS[$i]}"
    echo "$svc: http://localhost:${port}"
done
