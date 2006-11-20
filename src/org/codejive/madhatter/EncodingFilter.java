/*
 * [madhatter] Codejive CMS package
 * 
 * Copyright (C) 2006 Tako Schotanus
 * 
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 * 
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this library; see the file COPYING.  If not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA.
 * 
 * Linking this library statically or dynamically with other modules is
 * making a combined work based on this library.  Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * As a special exception, the copyright holders of this library give you
 * permission to link this library with independent modules to produce an
 * executable, regardless of the license terms of these independent
 * modules, and to copy and distribute the resulting executable under
 * terms of your choice, provided that you also meet, for each linked
 * independent module, the terms and conditions of the license of that
 * module.  An independent module is a module which is not derived from
 * or based on this library.  If you modify this library, you may extend
 * this exception to your version of the library, but you are not
 * obligated to do so.  If you do not wish to do so, delete this
 * exception statement from your version.
 * 
 * Created on October 15, 2006
 */
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
