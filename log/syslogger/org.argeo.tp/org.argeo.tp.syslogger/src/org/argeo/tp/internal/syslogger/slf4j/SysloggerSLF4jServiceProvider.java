package org.argeo.tp.internal.syslogger.slf4j;

import org.slf4j.ILoggerFactory;
import org.slf4j.IMarkerFactory;
import org.slf4j.spi.MDCAdapter;
import org.slf4j.spi.SLF4JServiceProvider;

/** Service provider using the SLF4J v2.0 mechanism. */
public class SysloggerSLF4jServiceProvider implements SLF4JServiceProvider {
	public static final String REQUESTED_API_VERSION = "2.0";

	private ILoggerFactory loggerFactory;

	@Override
	public ILoggerFactory getLoggerFactory() {
		return loggerFactory;
	}

	@Override
	public IMarkerFactory getMarkerFactory() {
		return null;
	}

	@Override
	public MDCAdapter getMDCAdapter() {
		return null;
	}

	@Override
	public String getRequestedApiVersion() {
		return REQUESTED_API_VERSION;
	}

	@Override
	public void initialize() {
		loggerFactory = new SystemLoggerFactory();
	}

}
