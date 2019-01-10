package org.lol.ivyconvertpom;

import java.io.File;

import org.apache.ivy.Ivy;
import org.apache.ivy.core.module.descriptor.DependencyDescriptor;
import org.apache.ivy.core.module.descriptor.ModuleDescriptor;
import org.apache.ivy.core.settings.IvySettings;
import org.apache.ivy.plugins.parser.m2.PomModuleDescriptorParser;
import org.apache.ivy.plugins.repository.url.URLResource;

public final class Application {

    public static void main(String[] args) throws Exception {
        final File pomFile = new File(args[0]);
        final File ivyFile = new File(args[1]);

        final Ivy ivy = Ivy.newInstance();
        ivy.configureDefault();
        ivy.pushContext();

        final IvySettings settings = ivy.getSettings();

        final String cachePath = System.getProperty(
                "ivyconvertpom.cache",
                settings.getDefaultCache().getAbsolutePath());
        System.out.println("Cache Directory Path: " + cachePath);
        settings.setDefaultCache(new File(cachePath));

        //final ResolveOptions resolveOptions = new ResolveOptions().setUseCacheOnly(true);

        ModuleDescriptor md = PomModuleDescriptorParser.getInstance().parseDescriptor(
            settings, pomFile.toURI().toURL(), false);

        for (DependencyDescriptor dd : md.getDependencies()) {
            System.out.println("DEBUG DEPENDENCY: " + dd.toString());
        }

        PomModuleDescriptorParser.getInstance().toIvyFile(pomFile.toURI().toURL().openStream(),
            new URLResource(pomFile.toURI().toURL()), ivyFile, md);

        System.exit(0);
    }
}

