package org.argeo.tp.internal.syslogger.slf4j;

import org.argeo.api.syslogger.SystemLoggingAdapter;
import org.slf4j.ILoggerFactory;

/** Wraps an Argeo syslogger. */
class SystemLoggerFactory implements ILoggerFactory {

	@Override
	public org.slf4j.Logger getLogger(String name) {
		SystemLoggingAdapter logger = SystemLoggingAdapter.getLog(name);
		return new ArgeoLogger(name, logger);
	}

}