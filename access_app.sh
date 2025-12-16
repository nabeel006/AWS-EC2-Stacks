#!/bin/bash
# Simple script to access the application via port-forward

echo "Starting port-forward for UI service..."
echo "Access the UI at: http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop"
echo ""

kubectl port-forward svc/ui-service 8080:80

