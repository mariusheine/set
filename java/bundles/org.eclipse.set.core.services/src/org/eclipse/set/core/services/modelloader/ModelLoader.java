/**
 * Copyright (c) 2018 DB Netz AG and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.core.services.modelloader;

import java.util.function.Consumer;

import org.eclipse.set.basis.constants.ValidationResult;
import org.eclipse.set.basis.files.ToolboxFile;
import org.eclipse.set.toolboxmodel.PlanPro.PlanPro_Schnittstelle;
import org.eclipse.swt.widgets.Shell;

/**
 * Manage UI oriented loading of a PlanPro Model.
 * 
 * @author Schaefer
 */
public interface ModelLoader {

	/**
	 * @param toolboxFile
	 *            the toolbox file to load the model from
	 * @param storeModel
	 *            the consumer to consume the loaded model
	 * @param shell
	 *            the shell
	 * @param ensureValid
	 *            ensure the loaded model is valid
	 * 
	 * @return whether the model was loaded (and stored) successfully
	 */
	public ValidationResult loadModel(ToolboxFile toolboxFile,
			Consumer<PlanPro_Schnittstelle> storeModel, Shell shell,
			boolean ensureValid);
}
