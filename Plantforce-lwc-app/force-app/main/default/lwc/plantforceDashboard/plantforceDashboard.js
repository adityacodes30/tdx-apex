import { LightningElement, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/chartjs';
// Import Apex methods
import getCrisisData from '@salesforce/apex/PlantforceDashboardController.getCrisisData';
import getMachineData from '@salesforce/apex/PlantforceDashboardController.getMachineData';

export default class PlantforceDashboard extends LightningElement {
    @track chartjsInitialized = false;
    @track crisisChart;
    @track machineChart;
    @track error; // General error tracking

    // Properties to hold wired data and errors
    wiredCrisisData;
    wiredMachineData;
    crisisChartData;
    machineChartData;
    crisisError;
    machineError;

    // Wire the Apex methods
    @wire(getCrisisData)
    wiredCrisisResult(result) {
        this.wiredCrisisData = result; // Store the raw wire result
        if (result.data) {
            console.log('Crisis Data Received:', JSON.parse(JSON.stringify(result.data)));
            // Process data for the chart
            console.log('Processing crisis data for chart...', result.data.pressureData, result.data.temperatureData);
            this.crisisChartData = {
                labels: result.data.labels,
                datasets: [
                    {
                        label: 'Avg Pressure (PSI)', // Updated label
                        data: result.data.pressureData,
                        borderColor: 'rgb(255, 99, 132)',
                        backgroundColor: 'rgba(255, 99, 132, 0.5)',
                        tension: 0.1
                    },
                    {
                        label: 'Avg Temperature (°C)', // Updated label
                        data: result.data.temperatureData,
                        borderColor: 'rgb(54, 162, 235)',
                        backgroundColor: 'rgba(54, 162, 235, 0.5)',
                        tension: 0.1
                    }
                ]
            };
            this.crisisError = undefined;
            // Attempt to initialize or update chart if library is ready
            if (this.chartjsInitialized) {
                this.initializeCrisisChart();
            }
        } else if (result.error) {
            console.error('Error fetching crisis data:', result.error);
            this.crisisError = result.error;
            this.crisisChartData = undefined;
        }
    }

    @wire(getMachineData)
    wiredMachineResult(result) {
        this.wiredMachineData = result; // Store the raw wire result
        if (result.data) {
            console.log('Machine Data Received:', JSON.parse(JSON.stringify(result.data)));
            // Process data for the chart
            this.machineChartData = {
                labels: result.data.labels,
                datasets: [
                    {
                        label: 'Raw Material 1 Qty', // Updated label
                        data: result.data.rawMaterial1Data,
                        backgroundColor: 'rgba(75, 192, 192, 0.5)',
                        borderColor: 'rgb(75, 192, 192)',
                        borderWidth: 1
                    },
                    {
                        label: 'Raw Material 2 Qty', // Updated label
                        data: result.data.rawMaterial2Data,
                        backgroundColor: 'rgba(153, 102, 255, 0.5)',
                        borderColor: 'rgb(153, 102, 255)',
                        borderWidth: 1
                    }
                ]
            };
            this.machineError = undefined;
             // Attempt to initialize or update chart if library is ready
            if (this.chartjsInitialized) {
                this.initializeMachineChart();
            }
        } else if (result.error) {
            console.error('Error fetching machine data:', result.error);
            this.machineError = result.error;
            this.machineChartData = undefined;
        }
    }

    renderedCallback() {
        if (this.chartjsInitialized) {
            return;
        }
        loadScript(this, chartjs)
            .then(() => {
                this.chartjsInitialized = true;
                this.error = undefined; // Clear general error on successful load
                console.log('Chart.js loaded successfully.');
                // Initialize charts if data is already available
                if (this.crisisChartData) {
                    this.initializeCrisisChart();
                }
                if (this.machineChartData) {
                    this.initializeMachineChart();
                }
            })
            .catch(error => {
                this.error = error;
                console.error('Error loading Chart.js', error);
            });
    }

    initializeCrisisChart() {
        if (!this.crisisChartData) {
            console.warn('Crisis chart data not available yet.');
            return; // Don't initialize if data isn't ready
        }
        const canvas = this.template.querySelector('canvas.crisisLineChart');
        if (!canvas) {
            console.error('Crisis chart canvas element not found during initialization.');
            return;
        }
        const ctx = canvas.getContext('2d');
        if (this.crisisChart) {
            this.crisisChart.destroy(); // Destroy previous instance if exists
        }
        console.log('Initializing Crisis Chart with data:', JSON.parse(JSON.stringify(this.crisisChartData)));
        this.crisisChart = new window.Chart(ctx, {
            type: 'line',
            data: this.crisisChartData, // Use fetched data
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: { position: 'top' },
                    title: { display: true, text: 'Crisis Monitoring (Avg Pressure & Temp - Last 10 Days)' } // Updated title
                },
                scales: { y: { beginAtZero: false } }
            }
        });
    }

     initializeMachineChart() {
        if (!this.machineChartData) {
            console.warn('Machine chart data not available yet.');
            return; // Don't initialize if data isn't ready
        }
        const canvas = this.template.querySelector('canvas.machineUsageChart');
         if (!canvas) {
            console.error('Machine usage chart canvas element not found during initialization.');
            return;
        }
        const ctx = canvas.getContext('2d');
        if (this.machineChart) {
            this.machineChart.destroy(); // Destroy previous instance if exists
        }
        console.log('Initializing Machine Chart with data:', JSON.parse(JSON.stringify(this.machineChartData)));
        this.machineChart = new window.Chart(ctx, {
            type: 'bar',
            data: this.machineChartData, // Use fetched data
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: { position: 'top' },
                    title: { display: true, text: 'Machine Raw Material Usage (Quantity)' } // Updated title
                },
                scales: { y: { beginAtZero: true } } // Removed max: 100 as data is quantity now
            }
        });
    }

    // Optional: Add disconnectedCallback for cleanup
    disconnectedCallback() {
         if (this.crisisChart) {
            this.crisisChart.destroy();
            this.crisisChart = null;
        }
        if (this.machineChart) {
            this.machineChart.destroy();
            this.machineChart = null;
        }
    }
}
