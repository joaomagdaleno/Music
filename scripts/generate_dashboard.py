import json
import os
import sys

# This script generates a simple HTML dashboard from coverage history
def generate_dashboard(history_file, output_html):
    try:
        with open(history_file, 'r') as f:
            history = json.load(f)
    except Exception:
        history = []

    # Simple Chart.js template
    html_template = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Music Project Quality Dashboard</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
            body { font-family: sans-serif; padding: 20px; background: #f4f4f9; }
            .container { max-width: 800px; margin: auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            h1 { color: #333; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Quality Trend (Code Coverage) - Music Project</h1>
            <canvas id="coverageChart"></canvas>
        </div>
        <script>
            const data = {{ DATA }};
            const labels = data.map(d => d.date);
            const percentages = data.map(d => d.percentage);

            const ctx = document.getElementById('coverageChart').getContext('2d');
            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Code Coverage %',
                        data: percentages,
                        borderColor: 'rgb(75, 192, 192)',
                        tension: 0.1,
                        fill: false
                    }]
                },
                options: {
                    scales: {
                        y: { beginAtZero: true, max: 100 }
                    }
                }
            });
        </script>
    </body>
    </html>
    """
    
    # Sort history by date if needed
    formatted_data = []
    for entry in history:
        formatted_data.append({
            'date': entry.get('timestamp', entry.get('date', 'Unknown')),
            'percentage': round(entry.get('percentage', 0), 2)
        })
    
    final_html = html_template.replace('{{ DATA }}', json.dumps(formatted_data))
    
    with open(output_html, 'w') as f:
        f.write(final_html)

if __name__ == "__main__":
    history = sys.argv[1] if len(sys.argv) > 1 else 'coverage_history.json'
    output = sys.argv[2] if len(sys.argv) > 2 else 'index.html'
    generate_dashboard(history, output)
