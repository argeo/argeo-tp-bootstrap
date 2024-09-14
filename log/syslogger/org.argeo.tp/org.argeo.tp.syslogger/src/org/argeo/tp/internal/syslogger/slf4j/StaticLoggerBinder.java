package org.argeo.tp.internal.syslogger.slf4j;

import org.slf4j.ILoggerFactory;
import org.slf4j.spi.LoggerFactoryBinder;

@Deprecated
public class StaticLoggerBinder implements LoggerFactoryBinder {
	public static final String REQUESTED_API_VERSION = "1.7";

	private static final StaticLoggerBinder SINGLETON = new StaticLoggerBinder();

	private final ILoggerFactory loggerFactory;

	protected StaticLoggerBinder() {
		loggerFactory = new SystemLoggerFactory();
	}

	@Override
	public ILoggerFactory getLoggerFactory() {
		return loggerFactory;
	}

	@Override
	public String getLoggerFactoryClassStr() {
		return SystemLoggerFactory.class.getName();
	}

	public static final StaticLoggerBinder getSingleton() {
		return SINGLETON;
	}

}
