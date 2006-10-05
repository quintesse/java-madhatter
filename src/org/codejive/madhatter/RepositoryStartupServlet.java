/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.codejive.madhatter;

import org.apache.jackrabbit.core.RepositoryImpl;
import org.apache.jackrabbit.core.config.RepositoryConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.xml.sax.InputSource;

import javax.jcr.Repository;
import javax.jcr.RepositoryException;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.Enumeration;
import java.util.Properties;

/**
 * The RepositoryStartupServlet starts a jackrabbit repository and
 * registers it with the JNDI environment.
 */
public class RepositoryStartupServlet extends HttpServlet {

    /** the default logger */
    private static final Logger log = LoggerFactory.getLogger(RepositoryStartupServlet.class);

    /** initial param name for the repository config location */
    public final static String INIT_PARAM_REPOSITORY_CONFIG = "repository-config";

    /** initial param name for the repository home directory */
    public final static String INIT_PARAM_REPOSITORY_HOME = "repository-home";

    /** initial param name for the repository name */
    public final static String INIT_PARAM_REPOSITORY_NAME = "repository-name";

    /** the registered repository */
    private Repository repository;

    /** the name of the repository as configured */
    private String repositoryName;

    /** the jndi context, created base on configuration */
    private InitialContext jndiContext;

    /**
     * Initializes the servlet
     * @throws ServletException
     */
    public void init() throws ServletException {
        super.init();
        log.info("RepositoryStartupServlet initializing...");
        initRepository();
        registerJNDI();
        log.info("RepositoryStartupServlet initialized.");
    }

    /**
     * destroy the servlet
     */
    public void destroy() {
        super.destroy();
        if (log == null) {
            log("RepositoryStartupServlet shutting down...");
        } else {
            log.info("RepositoryStartupServlet shutting down...");
        }
        shutdownRepository();
        unregisterJNDI();
        if (log == null) {
            log("RepositoryStartupServlet shut down.");
        } else {
            log.info("RepositoryStartupServlet shut down.");
        }
    }

    /**
     * Creates a new Repository based on configuration
     * @throws ServletException
     */
    private void initRepository() throws ServletException {
        // setup home directory
        String repHome = getServletConfig().getInitParameter(INIT_PARAM_REPOSITORY_HOME);
        if (repHome==null) {
            log.error(INIT_PARAM_REPOSITORY_HOME + " missing.");
            throw new ServletException(INIT_PARAM_REPOSITORY_HOME + " missing.");
        }
        File repositoryHome;
        try {
            if (repHome.startsWith("/WEB-INF/")) {
                String path = getServletContext().getRealPath(repHome);
                repositoryHome = new File(path).getCanonicalFile();
            } else {
                repositoryHome = new File(repHome).getCanonicalFile();
            }
        } catch (IOException e) {
            log.error(INIT_PARAM_REPOSITORY_HOME + " invalid." + e.toString());
            throw new ServletException(INIT_PARAM_REPOSITORY_HOME + " invalid." + e.toString());
        }
        log.info("  repository-home = " + repositoryHome.getPath());

        // get repository config
        String repConfig = getServletConfig().getInitParameter(INIT_PARAM_REPOSITORY_CONFIG);
        if (repConfig==null) {
            log.error(INIT_PARAM_REPOSITORY_CONFIG + " missing.");
            throw new ServletException(INIT_PARAM_REPOSITORY_CONFIG + " missing.");
        }
        log.info("  repository-config = " + repConfig);

        InputStream in = getServletContext().getResourceAsStream(repConfig);
        if (in==null) {
            try {
                in = new FileInputStream(new File(repositoryHome, repConfig));
            } catch (FileNotFoundException e) {
                log.error(INIT_PARAM_REPOSITORY_CONFIG + " invalid." + e.toString());
                throw new ServletException(INIT_PARAM_REPOSITORY_CONFIG + " invalid." + e.toString());
            }
        }

        // get repository name
        repositoryName = getServletConfig().getInitParameter(INIT_PARAM_REPOSITORY_NAME);
        if (repositoryName==null) {
            repositoryName="default";
        }
        log.info("  repository-name = " + repositoryName);

        try {
            repository = createRepository(new InputSource(in), repositoryHome);
        } catch (RepositoryException e) {
            throw new ServletException("Error while creating repository", e);
        }
    }

    /**
     * Shuts down the repository
     */
    private void shutdownRepository() {
        if (repository instanceof RepositoryImpl) {
            ((RepositoryImpl) repository).shutdown();
            repository = null;
        }
    }

    /**
     * Creates the repository for the given config and homedir.
     *
     * @param is
     * @param homedir
     * @return
     * @throws RepositoryException
     */
    protected Repository createRepository(InputSource is, File homedir)
            throws RepositoryException {
        RepositoryConfig config = RepositoryConfig.create(is, homedir.getAbsolutePath());
        return RepositoryImpl.create(config);
    }

    /**
     * Registers the repository in the JNDI context
     */
    private void registerJNDI() throws ServletException {
        // registering via jndi
        Properties env = new Properties();
        Enumeration names = getServletConfig().getInitParameterNames();
        while (names.hasMoreElements()) {
            String name = (String) names.nextElement();
            if (name.startsWith("java.naming.")) {
                String initParam = getServletConfig().getInitParameter(name);
                if (initParam.equals("")) {
                    log.info("  ignoring empty JNDI init param: " + name);
                } else {
                    env.put(name, initParam);
                    log.info("  adding property to JNDI environment: " + name + "=" + initParam);
                }
            }
        }
        try {
            jndiContext = new InitialContext(env);
            jndiContext.bind(repositoryName, repository);
            log.info("Repository bound to JNDI with name: " + repositoryName);
        } catch (NamingException e) {
            throw new ServletException("Unable to bind repository using JNDI.", e);
        }
    }

    /**
     * Unregisters the repository from the JNDI context
     */
    private void unregisterJNDI() {
        if (jndiContext != null) {
            try {
                jndiContext.unbind(repositoryName);
            } catch (NamingException e) {
                log("Error while unbinding repository from JNDI: " + e);
            }
        }
    }
}
