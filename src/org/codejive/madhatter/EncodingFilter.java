package org.codejive.madhatter;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This is an extremely simple filter that just set the request
 * and response character encodings to the value passed during
 * initialization.
 * 
 * @author tako
 */
public class EncodingFilter implements Filter {
	private FilterConfig filterConfig = null;
	private String encoding = null;
	
    private static final Logger log = LoggerFactory.getLogger(EncodingFilter.class);
	
	public void init(FilterConfig _filterConfig) throws ServletException {
		filterConfig = _filterConfig;
		encoding = filterConfig.getInitParameter("encoding");
		if (encoding == null) {
			// Let's at least use a sane default
			encoding = "UTF-8";
		}
		log.info("Set request/response character encoding to " + encoding);
	}
	
	public void destroy() {
		filterConfig = null;
	}
	
	public void doFilter(ServletRequest _request, ServletResponse _response, FilterChain _chain) throws IOException, ServletException {
		if (encoding != null) {
			_request.setCharacterEncoding(encoding);
			_response.setCharacterEncoding(encoding);
		}
		_chain.doFilter(_request, _response);
	}
}
