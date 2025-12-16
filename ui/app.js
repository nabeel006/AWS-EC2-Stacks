// Determine API URL based on how the app is accessed
// If accessed via localhost with port 8080 (port-forward), use direct backend URL
// Otherwise, use ingress path
function getApiUrl() {
    const host = window.location.hostname;
    const port = window.location.port;
    
    // If we're on localhost with port 8080, use direct backend URL
    if (host === "localhost" || host === "127.0.0.1") {
        if (port === "8080" || port === "") {
            return "http://localhost:5000/dashboard";
        }
    }
    // Default to ingress path
    return "/api/dashboard";
}

const API_URL = getApiUrl();

const refreshBtn = document.getElementById('refresh-btn');
const stackDisplay = document.getElementById('stack-data');
const listDisplay = document.getElementById('list-data');
const graphDisplay = document.getElementById('graph-data');
const errorMsg = document.getElementById('error-msg');

async function fetchData() {
    refreshBtn.disabled = true;
    refreshBtn.innerText = "Loading...";
    errorMsg.innerText = "";

    try {
        console.log("Fetching from:", API_URL);
        const response = await fetch(API_URL);
        console.log("Response status:", response.status);
        if (!response.ok) throw new Error(`Network response not ok: ${response.status} ${response.statusText}`);

        const data = await response.json();
        console.log("Received data:", data);

        // 1. C Stack
        if(data.stack_pop) {
            stackDisplay.innerHTML = `Value: ${data.stack_pop.value} <br> Status: ${data.stack_pop.status}`;
        } else {
            stackDisplay.innerText = data.stack_error || "Error";
        }

        // 2. Java List
        listDisplay.innerText = data.linked_list || data.linked_list_error || "Error";

        // 3. Python Graph
        if(data.graph) {
            graphDisplay.innerText = JSON.stringify(data.graph, null, 2);
        } else {
            graphDisplay.innerText = data.graph_error || "Error";
        }

    } catch (error) {
        console.error(error);
        errorMsg.innerText = "Could not reach Backend. Is Minikube Tunnel running?";
    } finally {
        refreshBtn.disabled = false;
        refreshBtn.innerText = "Fetch Data";
    }
}

refreshBtn.addEventListener('click', fetchData);