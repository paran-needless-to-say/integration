#!/bin/bash

echo "🚀 Starting Trace-X Platform..."
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo "Please create .env file with:"
    echo "  ETHERSCAN_API_KEY=your_api_key_here"
    echo ""
    exit 1
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Check if ETHERSCAN_API_KEY is set
if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "❌ ETHERSCAN_API_KEY is not set in .env"
    exit 1
fi

echo "✅ Environment variables loaded"
echo ""

# Start services in background
echo "📊 Starting Risk Scoring API (port 5001)..."
cd risk-scoring
source venv/bin/activate 2>/dev/null || python3 -m venv venv && source venv/bin/activate
pip install -q -r requirements.txt
python run_server.py > ../logs/risk-scoring.log 2>&1 &
RISK_PID=$!
cd ..

sleep 3
echo "✅ Risk Scoring API started (PID: $RISK_PID)"
echo ""

echo "🔧 Starting Backend API (port 8888)..."
cd backend
source venv/bin/activate 2>/dev/null || python3 -m venv venv && source venv/bin/activate
export ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY
pip install -q -e .
python main.py > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
cd ..

sleep 3
echo "✅ Backend API started (PID: $BACKEND_PID)"
echo ""

echo "🎨 Starting Frontend (port 5173)..."
cd frontend
npm install --silent
npm run dev > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

sleep 3
echo "✅ Frontend started (PID: $FRONTEND_PID)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 All services are running!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔗 Frontend:        http://localhost:5173"
echo "🔗 Backend:         http://localhost:8888"
echo "🔗 Risk Scoring:    http://localhost:5001"
echo ""
echo "📝 Logs:"
echo "   Risk Scoring:    tail -f logs/risk-scoring.log"
echo "   Backend:         tail -f logs/backend.log"
echo "   Frontend:        tail -f logs/frontend.log"
echo ""
echo "⏹️  To stop all services: ./scripts/stop-all.sh"
echo "   Or press Ctrl+C"
echo ""

# Save PIDs for cleanup
echo "$RISK_PID" > .pids/risk-scoring.pid
echo "$BACKEND_PID" > .pids/backend.pid
echo "$FRONTEND_PID" > .pids/frontend.pid

# Wait for Ctrl+C
trap "echo ''; echo '⏹️  Stopping all services...'; ./scripts/stop-all.sh; exit" INT TERM

echo "Waiting... (Press Ctrl+C to stop)"
wait

