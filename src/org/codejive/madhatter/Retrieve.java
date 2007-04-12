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
 * Created on October 28, 2006
 */
package org.codejive.madhatter;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Calendar;

import javax.jcr.LoginException;
import javax.jcr.Node;
import javax.jcr.Repository;
import javax.jcr.RepositoryException;
import javax.jcr.Session;
import javax.jcr.SimpleCredentials;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Servlet implementation class for Servlet: CreateRepo
 * 
 * @web.servlet name="Retrieve" display-name="Retrieve" description="Just a
 *              test servlet for retrieving information from the repo"
 * 
 * @web.servlet-mapping url-pattern="/Retrieve"
 * 
 */
public class Retrieve extends javax.servlet.http.HttpServlet implements javax.servlet.Servlet {

    private static final Logger log = LoggerFactory.getLogger(EncodingFilter.class);
    
    /*
     * (non-Java-doc)
     * 
     * @see javax.servlet.http.HttpServlet#doGet(HttpServletRequest request,
     *      HttpServletResponse response)
     */
    @Override
	protected void doGet(HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException {
        String path = "";
        if (request.getPathInfo() != null) {
            path += request.getPathInfo();
        }
        if (request.getParameter("path") != null) {
            path += request.getParameter("path");
        }
        if (path.startsWith("/")) {
            path = path.substring(1);
        }
        String uuid = request.getParameter("uuid");
        try {
            InitialContext context = new InitialContext();
            Repository repository = (Repository) context.lookup("java:comp/env/jcr/repository");
            Session session = repository.login(new SimpleCredentials("username", "password".toCharArray()));
            Node node = null;
            if (uuid != null && uuid.length() > 0) {
                node = session.getNodeByUUID(uuid);
            } else if (path != null && path.length() > 0) {
                Node root = session.getRootNode();
                node = root.getNode(path);
            }
            if (node != null) {
                String typeName = node.getPrimaryNodeType().getName();
                if (("nt:resource".equals(typeName)) || ("mad:content".equals(typeName))) {
                    String mimeType = node.getProperty("jcr:mimeType").getString();
                    String encoding = node.getProperty("jcr:encoding").getString();
                    InputStream data = node.getProperty("jcr:data").getStream();
                    Calendar modified = node.getProperty("jcr:lastModified").getDate();
                    
                    log.debug("Retrieving document " + node.getPath() + " (mime=" + mimeType + ", encoding=" + encoding + ")");
                    response.setContentType(mimeType);
                    response.setCharacterEncoding(encoding);
                    response.setDateHeader("Last-Modified", modified.getTime().getTime());
                    
                    if ("mad:content".equals(typeName)) {
                        String language = node.getProperty("mad:language").getString();
                        response.setHeader("Content-Language", language);
                    }
                    
                    ServletOutputStream out = response.getOutputStream();
                    copyStream(data, out);
                    out.flush();
                }
            }
        } catch (NamingException e) {
            throw new ServletException("Could not access repository", e);
        } catch (LoginException e) {
            throw new ServletException("Could not access repository", e);
        } catch (RepositoryException e) {
            throw new ServletException("Could not access repository", e);
        }
    }

   private void copyStream(InputStream in, OutputStream out) throws IOException {
       byte buf[] = new byte[1024];
       int s;
       while ((s = in.read(buf)) > 0) {
           out.write(buf, 0, s);
       }
    }

 /*
     * (non-Java-doc)
     * 
     * @see javax.servlet.http.HttpServlet#doPost(HttpServletRequest request,
     *      HttpServletResponse response)
     */
    @Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // TODO Auto-generated method stub
    }
}