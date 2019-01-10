/*
 *  Licensed to the Apache Software Foundation (ASF) under one or more
 *  contributor license agreements.  See the NOTICE file distributed with
 *  this work for additional information regarding copyright ownership.
 *  The ASF licenses this file to You under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package org.lol.ivyconvertpom;

import java.io.File;
import java.net.MalformedURLException;
import java.text.ParseException;

import org.apache.ivy.core.settings.IvySettings;
import org.apache.ivy.core.module.descriptor.ModuleDescriptor;
import org.apache.ivy.plugins.parser.m2.PomModuleDescriptorParser;
import org.apache.ivy.plugins.repository.url.URLResource;

/**
 * Convert a pom to an ivy file
 */
public class IvyConvertPom {
    public static void convert(final IvySettings ivySettings, final File pomFile, final File ivyFile) {
        try {
            if (pomFile == null) {
                throw new RuntimeException("source pom file is required for convertpom task");
            }
            if (ivyFile == null) {
                throw new RuntimeException("destination ivy file is required for convertpom task");
            }
            ModuleDescriptor md = PomModuleDescriptorParser.getInstance().parseDescriptor(
                ivySettings, pomFile.toURI().toURL(), false);
            PomModuleDescriptorParser.getInstance().toIvyFile(pomFile.toURI().toURL().openStream(),
                new URLResource(pomFile.toURI().toURL()), ivyFile, md);
        } catch (MalformedURLException e) {
            throw new RuntimeException("unable to convert given pom file to url: " + pomFile + ": "
                    + e, e);
        } catch (ParseException e) {
            System.out.println(e.getMessage());
            throw new RuntimeException("syntax errors in pom file " + pomFile + ": " + e, e);
        } catch (Exception e) {
            throw new RuntimeException("impossible convert given pom file to ivy file: " + e
                    + " from=" + pomFile + " to=" + ivyFile, e);
        }
    }
}
