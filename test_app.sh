#!/bin/bash
# Test script to verify the application is working

echo "=== Testing Application ==="
echo ""

# Start port-forwards in background
echo "Starting port-forwards..."
kubectl port-forward svc/ui-service 8080:80 > /tmp/ui-port-forward.log 2>&1 &
UI_PID=$!
kubectl port-forward svc/backend-service 5000:5000 > /tmp/backend-port-forward.log 2>&1 &
BACKEND_PID=$!

# Wait for port-forwards to be ready
sleep 3

echo "1. Testing UI Service..."
if curl -s http://localhost:8080/ | grep -q "K8s Data Dashboard"; then
    echo "   ✅ UI is accessible"
else
    echo "   ❌ UI is NOT accessible"
fi

echo ""
echo "2. Testing Backend API..."
BACKEND_RESPONSE=$(curl -s http://localhost:5000/dashboard)
if echo "$BACKEND_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); exit(0 if ('stack_pop' in d or 'stack_error' in d) and ('linked_list' in d or 'linked_list_error' in d) and ('graph' in d or 'graph_error' in d) else 1)" 2>/dev/null; then
    echo "   ✅ Backend API is working"
    echo "   Response preview:"
    echo "$BACKEND_RESPONSE" | python3 -m json.tool | head -10
else
    echo "   ❌ Backend API is NOT working correctly"
    echo "   Response: $BACKEND_RESPONSE"
fi

echo ""
echo "3. Testing CORS..."
CORS_HEADERS=$(curl -s -H "Origin: http://localhost:8080" -I http://localhost:5000/dashboard 2>&1 | grep -i "access-control")
if [ -n "$CORS_HEADERS" ]; then
    echo "   ✅ CORS headers present"
    echo "   $CORS_HEADERS"
else
    echo "   ⚠️  CORS headers not found (might still work)"
fi

echo ""
echo "=== Access Instructions ==="
echo "UI: http://localhost:8080"
echo "Backend API: http://localhost:5000/dashboard"
echo ""
echo "Press Ctrl+C to stop port-forwards"

# Cleanup on exit
trap "kill $UI_PID $BACKEND_PID 2>/dev/null; exit" INT TERM

# Wait
wait

