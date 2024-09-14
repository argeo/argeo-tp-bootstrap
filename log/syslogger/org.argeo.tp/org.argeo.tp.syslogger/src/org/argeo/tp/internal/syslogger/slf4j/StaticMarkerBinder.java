package org.argeo.tp.internal.syslogger.slf4j;

import org.slf4j.IMarkerFactory;
import org.slf4j.spi.MarkerFactoryBinder;

/** Required for build */
public class StaticMarkerBinder implements MarkerFactoryBinder {
    public static final StaticMarkerBinder SINGLETON = new StaticMarkerBinder();

    private StaticMarkerBinder() {
    }

    public static StaticMarkerBinder getSingleton() {
        return SINGLETON;
    }

    public IMarkerFactory getMarkerFactory() {
    	return null;
    }

    public String getMarkerFactoryClassStr() {
    	return null;
    }

}
