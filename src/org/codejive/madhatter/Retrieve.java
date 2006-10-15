package org.codejive.madhatter;

import java.io.IOException;
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
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

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
    /*
     * (non-Java-doc)
     * 
     * @see javax.servlet.http.HttpServlet#HttpServlet()
     */
    public Retrieve() {
        super();
    }

    /*
     * (non-Java-doc)
     * 
     * @see javax.servlet.http.HttpServlet#doGet(HttpServletRequest request,
     *      HttpServletResponse response)
     */
    @Override
	protected void doGet(HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException {
        String path = request.getParameter("path");
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
                String mimeType = node.getProperty("jcr:mimeType").getString();
                String encoding = node.getProperty("jcr:encoding").getString();
                String data = node.getProperty("jcr:data").getString();
                Calendar modified = node.getProperty("jcr:lastModified").getDate();
                
                response.setContentType(mimeType);
                response.setCharacterEncoding(encoding);
                response.setDateHeader("Last-Modified", modified.getTime().getTime());
                response.getWriter().write(data);
                response.getWriter().flush();
            }
        } catch (NamingException e) {
            throw new ServletException("Could not access repository", e);
        } catch (LoginException e) {
            throw new ServletException("Could not access repository", e);
        } catch (RepositoryException e) {
            throw new ServletException("Could not access repository", e);
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