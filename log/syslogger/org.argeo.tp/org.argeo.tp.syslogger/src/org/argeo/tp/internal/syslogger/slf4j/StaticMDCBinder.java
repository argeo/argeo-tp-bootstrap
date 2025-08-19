package org.argeo.tp.internal.syslogger.slf4j;

import org.slf4j.spi.MDCAdapter;

/** Required for build */
@Deprecated
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
