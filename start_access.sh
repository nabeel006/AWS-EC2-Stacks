#!/bin/bash
# Start port-forward for both UI and Backend services

echo "Starting port-forwards..."
echo ""
echo "UI will be available at: http://localhost:8080"
echo "Backend API will be available at: http://localhost:5000"
echo ""
echo "Press Ctrl+C to stop all port-forwards"
echo ""

# Start both port-forwards in the background
kubectl port-forward svc/ui-service 8080:80 &
UI_PID=$!
kubectl port-forward svc/backend-service 5000:5000 &
BACKEND_PID=$!

# Wait for user interrupt
trap "kill $UI_PID $BACKEND_PID 2>/dev/null; exit" INT TERM

# Wait for processes
wait

