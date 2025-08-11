import React, { useState } from 'react';

const ProcessingForm = ({ selectedFunction, uploadedFiles, onProcess, processing }) => {
  const [parameters, setParameters] = useState({});
  const [selectedFiles, setSelectedFiles] = useState([]);

  const handleParameterChange = (paramName, value) => {
    setParameters(prev => ({
      ...prev,
      [paramName]: value
    }));
  };

  const handleFileSelection = (fileName, isSelected) => {
    setSelectedFiles(prev =>
      isSelected
        ? [...prev, fileName]
        : prev.filter(f => f !== fileName)
    );
  };

  const handleSubmit = (e) => {
    e.preventDefault();

    const formData = new FormData();
    formData.append('function_name', selectedFunction);

    // Add selected files
    selectedFiles.forEach(fileName => {
      const file = uploadedFiles.find(f => f.name === fileName);
      if (file) {
        formData.append('files', file);
      }
    });

    // Add parameters
    Object.entries(parameters).forEach(([key, value]) => {
      if (value !== '' && value !== null && value !== undefined) {
        formData.append(key, value);
      }
    });

    onProcess(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* File Selection */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Select Files to Process
        </label>
        <div className="space-y-2">
          {uploadedFiles.map((file, index) => (
            <label key={index} className="flex items-center space-x-2">
              <input
                type="checkbox"
                className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                onChange={(e) => handleFileSelection(file.name, e.target.checked)}
              />
              <span className="text-sm text-gray-700">{file.name}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Dynamic Parameters */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Function Parameters
        </label>
        <div className="space-y-4">
          {/* Common parameters based on function type */}
          {selectedFunction === 'compare_dataframes' && (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Join Keys (comma-separated)
                </label>
                <input
                  type="text"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="id,name"
                  onChange={(e) => handleParameterChange('join_keys', e.target.value)}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Comparison Type
                </label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  onChange={(e) => handleParameterChange('comparison_type', e.target.value)}
                >
                  <option value="">Select type</option>
                  <option value="differences">Differences</option>
                  <option value="similarities">Similarities</option>
                  <option value="both">Both</option>
                </select>
              </div>
            </div>
          )}

          {selectedFunction === 'merge_dataframes' && (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Join Keys (comma-separated)
                </label>
                <input
                  type="text"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="id,name"
                  onChange={(e) => handleParameterChange('join_keys', e.target.value)}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Join Type
                </label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  onChange={(e) => handleParameterChange('join_type', e.target.value)}
                >
                  <option value="inner">Inner</option>
                  <option value="left">Left</option>
                  <option value="right">Right</option>
                  <option value="outer">Outer</option>
                </select>
              </div>
            </div>
          )}

          {selectedFunction === 'aggregate_dataframe' && (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Group By Columns (comma-separated)
                </label>
                <input
                  type="text"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="category,region"
                  onChange={(e) => handleParameterChange('group_by', e.target.value)}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Aggregation Functions
                </label>
                <input
                  type="text"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="sum,avg,count"
                  onChange={(e) => handleParameterChange('agg_functions', e.target.value)}
                />
              </div>
            </div>
          )}

          {selectedFunction === 'pivot_dataframe' && (
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Index Column
                </label>
                <input
                  type="text"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="date"
                  onChange={(e) => handleParameterChange('index_col', e.target.value)}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Columns
                </label>
                <input
                  type="text"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="category"
                  onChange={(e) => handleParameterChange('columns', e.target.value)}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Values
                </label>
                <input
                  type="text"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="amount"
                  onChange={(e) => handleParameterChange('values', e.target.value)}
                />
              </div>
            </div>
          )}

          {/* Generic output format selection */}
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">
              Output Format
            </label>
            <select
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              onChange={(e) => handleParameterChange('output_format', e.target.value)}
            >
              <option value="csv">CSV</option>
              <option value="json">JSON</option>
              <option value="both">Both</option>
            </select>
          </div>
        </div>
      </div>

      {/* Submit Button */}
      <div className="flex justify-end">
        <button
          type="submit"
          disabled={processing || selectedFiles.length === 0}
          className={`px-6 py-2 rounded-md font-medium ${
            processing || selectedFiles.length === 0
              ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
              : 'bg-blue-600 text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500'
          }`}
        >
          {processing ? (
            <div className="flex items-center space-x-2">
              <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
              <span>Processing...</span>
            </div>
          ) : (
            'Process Data'
          )}
        </button>
      </div>
    </form>
  );
};

export default ProcessingForm;
