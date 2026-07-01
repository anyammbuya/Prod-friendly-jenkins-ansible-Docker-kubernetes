
/* When there is a git push to maven-project-webapp, this pipeline job looks
   and executes the Jenkinsfile
*/
pipelineJob('webapp-pipeline') {

 // With parameters we configure the Active Choices to read and display old versions of our build in a dropdown list
    parameters {
        booleanParam('IS_ROLLBACK', false, 'Enable Rollback Mode')
        activeChoiceReactiveParam('ROLLBACK_VERSION') {
            description('Select a WAR from EFS History')
            choiceType('SINGLE_SELECT')
            groovyScript {
                script("""
                    def dir = new File("/mnt/efs_deploy/old_versions/")
                    if (dir.exists()) {
                        return dir.list().findAll { it.endsWith(".war") }.sort().reverse()
                    } else {
                        return ["No Backups Found"]
                    }
                """)
            }
            referencedParameter('IS_ROLLBACK')
        }
    }
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('git@github.com:KingstonLtd/maven-project-webapp.git')
                        credentials('github-ssh-key')
                    }
                    branch('main')
                }
            }
            scriptPath('Jenkinsfile')
        }
    } 
    triggers {
        githubPush()
    }
}
