import React from 'react';

const ResultsDisplay = ({ results, onDownload }) => {
  const formatValue = (value) => {
    if (typeof value === 'object' && value !== null) {
      return JSON.stringify(value, null, 2);
    }
    return String(value);
  };

  const renderMetrics = (metrics) => {
    if (!metrics || typeof metrics !== 'object') return null;

    return (
      <div className="space-y-2">
        {Object.entries(metrics).map(([key, value]) => (
          <div key={key} className="flex justify-between items-center py-1">
            <span className="text-sm font-medium text-gray-700 capitalize">
              {key.replace(/_/g, ' ')}:
            </span>
            <span className="text-sm text-gray-600 font-mono">
              {formatValue(value)}
            </span>
          </div>
        ))}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Status */}
      <div className="flex items-center space-x-2">
        <div className="flex-shrink-0">
          {results.status === 'success' ? (
            <svg className="h-5 w-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
          ) : (
            <svg className="h-5 w-5 text-red-500" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
            </svg>
          )}
        </div>
        <span className={`font-medium ${results.status === 'success' ? 'text-green-800' : 'text-red-800'}`}>
          {results.status === 'success' ? 'Processing completed successfully' : 'Processing failed'}
        </span>
      </div>

      {/* Execution Time */}
      {results.execution_time && (
        <div className="text-sm text-gray-600">
          <span className="font-medium">Execution time:</span> {results.execution_time}
        </div>
      )}

      {/* Metrics */}
      {results.metrics && (
        <div className="bg-gray-50 rounded-lg p-4">
          <h3 className="font-medium text-gray-900 mb-3">Processing Metrics</h3>
          {renderMetrics(results.metrics)}
        </div>
      )}

      {/* Summary */}
      {results.summary && (
        <div className="bg-blue-50 rounded-lg p-4">
          <h3 className="font-medium text-blue-900 mb-2">Summary</h3>
          <p className="text-sm text-blue-800">{results.summary}</p>
        </div>
      )}

      {/* Output Files */}
      {results.output_files && results.output_files.length > 0 && (
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <h3 className="font-medium text-gray-900 mb-3">Output Files</h3>
          <div className="space-y-2">
            {results.output_files.map((file, index) => (
              <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                <div className="flex items-center space-x-2">
                  <svg className="h-4 w-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                  <span className="text-sm font-medium text-gray-700">{file}</span>
                </div>
                <button
                  onClick={() => onDownload(file)}
                  className="px-3 py-1 text-xs font-medium text-blue-600 bg-blue-100 rounded hover:bg-blue-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  Download
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Data Preview */}
      {results.preview && (
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <h3 className="font-medium text-gray-900 mb-3">Data Preview</h3>
          <div className="overflow-x-auto">
            <pre className="text-xs text-gray-600 bg-gray-50 p-3 rounded border max-h-64 overflow-y-auto">
              {typeof results.preview === 'string' ? results.preview : JSON.stringify(results.preview, null, 2)}
            </pre>
          </div>
        </div>
      )}

      {/* Session Info */}
      {results.session_id && (
        <div className="text-xs text-gray-500">
          <span className="font-medium">Session ID:</span> {results.session_id}
        </div>
      )}
    </div>
  );
};

export default ResultsDisplay;
