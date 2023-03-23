package org.slf4j.impl;

import org.slf4j.spi.MDCAdapter;

/** Required for build */
public class StaticMDCBinder {
    public static final StaticMDCBinder SINGLETON = new StaticMDCBinder();

    private StaticMDCBinder() {
    }

    public static final StaticMDCBinder getSingleton() {
        return SINGLETON;
    }

    public MDCAdapter getMDCA() {
    	return null;
    }

    public String getMDCAdapterClassStr() {
    	return null;
    }
}
