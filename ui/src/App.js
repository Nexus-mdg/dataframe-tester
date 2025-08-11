import React, { useState, useEffect } from 'react';
import axios from 'axios';
import FileUpload from './components/FileUpload';
import FunctionSelector from './components/FunctionSelector';
import ProcessingForm from './components/ProcessingForm';
import ResultsDisplay from './components/ResultsDisplay';

// API base URL - this will work from the browser to reach the API
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8651';

function App() {
  const [availableFunctions, setAvailableFunctions] = useState([]);
  const [selectedFunction, setSelectedFunction] = useState('');
  const [uploadedFiles, setUploadedFiles] = useState([]);
  const [processing, setProcessing] = useState(false);
  const [results, setResults] = useState(null);
  const [error, setError] = useState(null);
  const [sessionId, setSessionId] = useState(null);

  useEffect(() => {
    fetchAvailableFunctions();
  }, []);

  const fetchAvailableFunctions = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/functions`);
      setAvailableFunctions(response.data.functions);
    } catch (err) {
      setError('Failed to fetch available functions');
      console.error(err);
    }
  };

  const handleFileUpload = (files) => {
    setUploadedFiles(files);
    setResults(null);
    setError(null);
  };

  const handleFunctionSelect = (functionName) => {
    setSelectedFunction(functionName);
    setResults(null);
    setError(null);
  };

  const handleProcessing = async (formData) => {
    setProcessing(true);
    setError(null);
    setResults(null);

    try {
      const response = await axios.post(`${API_BASE_URL}/api/process`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      setResults(response.data);
      setSessionId(response.data.session_id);
    } catch (err) {
      setError(err.response?.data?.error || 'Processing failed');
      console.error(err);
    } finally {
      setProcessing(false);
    }
  };

  const handleDownload = async (filename) => {
    if (!sessionId) return;

    try {
      const response = await axios.get(`${API_BASE_URL}/api/download/${sessionId}/${filename}`, {
        responseType: 'blob',
      });

      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', filename);
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (err) {
      setError('Download failed');
      console.error(err);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-4 py-8">
        <header className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            DataFrame Tester
          </h1>
          <p className="text-lg text-gray-600">
            Upload, process, and analyze your data files with powerful DataFrame operations
          </p>
        </header>

        <div className="max-w-4xl mx-auto space-y-8">
          {/* File Upload Section */}
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-2xl font-semibold text-gray-800 mb-4">
              Upload Data Files
            </h2>
            <FileUpload onFileUpload={handleFileUpload} />
          </div>

          {/* Function Selection */}
          {uploadedFiles.length > 0 && (
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-2xl font-semibold text-gray-800 mb-4">
                Select Processing Function
              </h2>
              <FunctionSelector
                functions={availableFunctions}
                selectedFunction={selectedFunction}
                onFunctionSelect={handleFunctionSelect}
              />
            </div>
          )}

          {/* Processing Form */}
          {selectedFunction && (
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-2xl font-semibold text-gray-800 mb-4">
                Configure Processing
              </h2>
              <ProcessingForm
                selectedFunction={selectedFunction}
                uploadedFiles={uploadedFiles}
                onProcess={handleProcessing}
                processing={processing}
              />
            </div>
          )}

          {/* Error Display */}
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <div className="flex">
                <div className="text-red-400">
                  <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                  </svg>
                </div>
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-red-800">Error</h3>
                  <div className="mt-2 text-sm text-red-700">{error}</div>
                </div>
              </div>
            </div>
          )}

          {/* Results Display */}
          {results && (
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-2xl font-semibold text-gray-800 mb-4">
                Results
              </h2>
              <ResultsDisplay
                results={results}
                onDownload={handleDownload}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;
