import React, { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';

interface JavaInfo {
  version: string;
  path: string;
  is_valid: boolean;
}

export const JavaInfo: React.FC = () => {
  const [javaInstallations, setJavaInstallations] = useState<JavaInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    checkJavaInstallations();
  }, []);

  const checkJavaInstallations = async () => {
    try {
      setLoading(true);
      const installations = await invoke<JavaInfo[]>('check_java_installation');
      setJavaInstallations(installations);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to check Java installations');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="java-info">
      <h2>Java Installations</h2>
      
      {error && <div className="error-message">{error}</div>}

      {loading ? (
        <div className="loading">Checking Java installations...</div>
      ) : javaInstallations.length === 0 ? (
        <div className="no-java">
          <p>No Java installations found. Please install Java to run Minecraft servers.</p>
          <p>Recommended: Java 17 or newer for Minecraft 1.17+</p>
        </div>
      ) : (
        <div className="java-list">
          {javaInstallations.map((java, index) => (
            <div key={index} className="java-card">
              <h3>Java {java.version}</h3>
              <p>Path: {java.path}</p>
              <p>Status: {java.is_valid ? 'Valid' : 'Invalid'}</p>
            </div>
          ))}
        </div>
      )}

      <button onClick={checkJavaInstallations} className="refresh-button">
        Refresh Java Installations
      </button>
    </div>
  );
}; 