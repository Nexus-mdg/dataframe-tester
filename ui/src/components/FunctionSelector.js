import React from 'react';

const FunctionSelector = ({ functions, selectedFunction, onFunctionSelect }) => {
  // Handle case where functions is undefined or not yet loaded
  if (!functions || !Array.isArray(functions)) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="text-center">
          <svg className="animate-spin h-8 w-8 text-blue-500 mx-auto mb-2" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          <p className="text-gray-600">Loading available functions...</p>
        </div>
      </div>
    );
  }

  if (functions.length === 0) {
    return (
      <div className="text-center p-8">
        <p className="text-gray-600">No functions available</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {functions.map((func) => (
          <div
            key={func.name}
            className={`border rounded-lg p-4 cursor-pointer transition-colors ${
              selectedFunction === func.name
                ? 'border-blue-500 bg-blue-50'
                : 'border-gray-200 hover:border-gray-300'
            }`}
            onClick={() => onFunctionSelect(func.name)}
          >
            <h3 className="font-semibold text-gray-900 mb-2">{func.name}</h3>
            <p className="text-sm text-gray-600 mb-3">{func.description}</p>
            <div className="space-y-1">
              <p className="text-xs font-medium text-gray-700">Parameters:</p>
              {func.parameters && func.parameters.length > 0 ? (
                <ul className="text-xs text-gray-600 space-y-1">
                  {func.parameters.map((param, index) => (
                    <li key={index} className="flex items-center space-x-1">
                      <span className="font-medium">{param.name}:</span>
                      <span>{param.type}</span>
                      {param.required && (
                        <span className="text-red-500 text-xs">*</span>
                      )}
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-xs text-gray-500 italic">No parameters required</p>
              )}
            </div>
          </div>
        ))}
      </div>

      {selectedFunction && (
        <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <p className="text-sm text-blue-800">
            <span className="font-medium">Selected:</span> {selectedFunction}
          </p>
        </div>
      )}
    </div>
  );
};

export default FunctionSelector;
