# encoding: utf-8
{
  :'es' => {
    :application => {
      :require_ssh_keys_error => "Primero necesita establecer su llave pública",
      :no_commits_notice => "El repositorio aún no tiene ningún commit",
    },
    :admin => {
      :users_controller => {
        :create_notice => 'El usuario ah sido creado.',
        :suspend_notice => "El usuario %{user_name} ah sido suspendido.",
        :suspend_error => "No se ha logrado suspender al usuario %{user_name}.",
        :unsuspend_notice => "El usuario %{user_name} ah sido reactivado.",
        :unsuspend_error => "No se ha logrado reactivar al usuario %{user_name}."
      },
      :check_admin => "Sólo para administradores"
    },
    :mailer => {
      :repository_clone => "%{login} ah clonado %{slug}/%{parent}",
      :request_notification => "%{login} ha solicitado un merge en %{title}",
      :new_password => "Su nueva contraseña",
      :subject  => 'Por favor active su nueva cuenta',
      :activated => '¡Su cuenta ha sido activada!',
    },
    :blobs_controller => {
      :raw_error => "Blob es demasiado grande. Clone el repositorio localmente para verlo",
    },
    :comments_controller => {
      :create_success => "Su comentario fue agregado",
    },
    :committers_controller => {
      :create_error_not_found => "No se pudo encontrar un usuario con ese nombre",
      :create_error_already_commiter => "No se pudo agregar el usuario o el usuario ya es un committer",
      :destroy_success => "El usuario fue quitado del repositorio",
      :destroy_error => "No se ha podido quitar al usuario del repositorio",
      :find_repository_error => "Usted no es el dueño de este repositorio",
    },
    :keys_controller => {
      :create_notice => "La llave ah sido agregada",
      :destroy_notice => "La llave ah sido eliminada",
    },
    :merge_requests_controller => {
      :create_success => "Usted ah enviado una solicitud de merge a \"%{name}\"",
      :resolve_notice => "La solicitud de merge ha sido marcada como %{status}",
      :update_success => "La solicitud de merge ha sido actualizada",
      :destroy_success => "La solicitud de merge ha sido retirada",
      :assert_resolvable_error => "Usted no tiene permisos para resolver esta solicitud de merge",
      :assert_ownership_error => "Usted no es el autor de esta solicitud de merge"
    },
    :projects_controller => {
      :update_error => "Usted no es el dueño de este proyecto",
      :destroy_error => "Usted no es el dueño de este proyecto, o el proyecto tiene clones",
    },
    :repositories_controller => {
      :new_error => "Disculpe, no se puede clonar un repositorio vacío",
      :create_error => "Disculpe, no se puede clonar un repositorio vacío",
      :destroy_notice => "El repositorio ha sido borrado",
      :destroy_error => "Usted no es el dueño de este repositorio",
      :adminship_error => "Disculpe, sólo los administradores de proyecto tienen permiso para hacer eso",
    },
    :trees_controller => {
      :archive_error => "El repositorio especificado o el SHA es inválido"
    },
    :users_controller => {
      :activate_notice => "Su cuenta ha sido activada, ¡bienvenido!",
      :activate_error => "Código de activación inválido",
      :reset_password_notice => "Se le ha enviado a su correo electrónico una nueva contraseña",
      :reset_password_error => "Correo electrónico inválido",
    },
    :application_helper => {
      :notice_for => "Este/a %{class_name} se está creando,<br /> en breve estará pronto/a&hellip;",
      :event_status_created => "proyecto creado",
      :event_status_deleted => "proyecto borrado",
      :event_status_updated => "proyecto actualizado",
      :event_status_cloned => "clonado",
      :event_status_deleted => "borrado",
      :event_status_pushed => "comiteado",
      :event_status_started => "desarrollo iniciado",
      :event_branch_created => "branch creado",
      :event_branch_deleted => "branch borrado",
      :event_tagged => "tagueado",
      :event_tag_deleted => "tag borrado",
      :event_committer_added => "committer agregado",
      :event_committer_removed => "committer quitado",
      :event_commented => "comentado",
      :event_requested_merge_of => "merge solicitado de",
      :event_resolved_merge_request => "solicitud de merge resuelta",
      :event_updated_merge_request => "solicitud de merge actualizada",
      :event_deleted_merge_request => "solicitud de merge borrada",
    },
    :project => {
      :format_slug_validation => "debe coincidir con algo en el rango de [a-z0-9_\-]+",
      :http_required => "Debe comenzar con http(s)",
    },
    :user => {
      :invalid_url => "URL inválida",
    },
    :views => {
      :layout => {
        :system_notice => "Notificación del sistema",
        :home => "Inicio",
        :dashboard => "Panel",
        :admin => "Administración",
        :projects => "Proyectos",
        :search => "Buscar",
        :faq => "Preguntas frecuentes",
        :about => "Acerca de&hellip;",
        :my_account => "Mi cuenta",
        :logout => "Salir",
        :project_overview => "Resumen del proyecto",
        :repositories => "Repositorios",
        :user_mgt => "Administración de usuarios",
        :discussion => "Grupo de discusión",
      },
      :site => {
        :page_title => "Hospedaje gratuito de proyectos Open Source",
        :description => "<strong>Gitorious</strong> pretende proveer una manera\ninteresante de hacer desarrollo opensource colaborativo y distribuido",
        :for_projects => "Para proyectos",
        :for_contributors => "Para colaboradores",
        :newest_projects => "Los proyectos más nuevos",
        :view_more => "Ver más &raquo;",
        :dashboard => {
          :page_title => "Panel de %{login}",
          :activities => "Actividades",
          :your_projects => "Sus proyectos:",
          :your_clones => "Sus clones de repositorios",
          :your_account => "Su cuenta",
          :your_profile => "Su perfil de usuario",
          :projects => "Proyectos",
          :clones => "Clones de repositorios",
        },
      },
      :events => {
        :page_title => "Eventos",
        :activities => "Actividades de Gitorious",
        :system_activities => "Actividades del sistema",
      },
      :keys => {
        :edit_title => "Editar una llave SSH",
        :ssh_keys => "Sus llaves SSH",
        :add_ssh_key => "Agragar una llave SSH",
        :add_title => "Agregar una nueva llave pública SSH",
        :your_public_key => "Su llave pública",
        :hint => "Generalmente está ubicada en ~/.ssh/id_rsa.pub o ~/.ssh/id_dsa.pub.<br />Si quiere usar múltiples claves necesitará agregarlas por separado",
      },
      :users => {
        :activated => "¿Activado?",
        :suspended => "¿Suspendido?",
        :admin => "¿Administrador?",
        :suspend => "Suspender",
        :unsuspend => "Reactivar",
        :create_btn => "Crear un nuevo usuario",
        :is_admin => "¿Es administrator?",
        :forgot_title => "¿Olvidó su contraseña?",
        :send_new_passwd => 'Enviarme una nueva contraseña',
        :openid_build_title => 'Complete your registration', # translation missing
        :openid_build_description => 'You need to enter the following details:', # translation missing
        :openid_failed => 'OpenID authentication has failed.', # translation missing
        :openid_canceled => 'OpenID authentication was canceled.', # translation missing
        :create_title => "Cree un nuevo usuario o <a href=\"%{path}\">entre directamente con su OpenID</a>",
        :create_description => "Crear una cuenta de usuario le permite crear su propio proyecto o participar en el desarrollo de otro proyecto.",
        :member_for => "Miembro para",
        :this_week => {
          :one => "commit hasta ahora en esta semana",
          :other => "commits hasta ahora en esta semana",
        },
        :about => "acerca de %{about}",
        :edit_title => "Editar su cuenta",
        :realname => "Nombre real",
        :url => "URL <small>blog, etc</small>",
        :openid => "OpenID",
        :my_account => "Mi cuenta",
        :chg_passwd => "Cambiar contraseña",
        :new_passwd => "Nueva contraseña",
        :new_passwd_conf => "Repetir la nueva contraseña",
        :edit_details => "Editar detalles",
        :show_title => "Cuenta",
        :details_title => "Detalles de la cuenta",
        :edit_link => "editar",
        :username => "Usuario",
        :create => "crear una cuenta",
      },
      :logs => {
        :page_title => "Commits en %{repo} en %{title}",
        :commitlog => "Registro de commits para %{repo}:%{param} en %{title}",
        :project => "Proyecto",
        :maintainer => "Responsable",
        :head_tree => "árbol HEAD",
        :branches => "Branches",
        :tags => "Tags",
      },
      :blobs => {
        :page_title => "%{path} - %{repo} en %{title}",
        :wrap => "Modo Softwrap",
        :title => "Blob de <code>%{path}</code>",
        :raw => "dato blob puro",
        :too_big => "Este archivo es demasiado grande para ser presentado en un tiempo razonable, <a href=\"%{path}\">intente ver los datos puros</a>",
        :message => "No es seguro que podamos presentar este blob de forma adecuada, <a href=\"%{path}\">intente ver los datos puros</a> y vea si su navegador sabe cómo hacerlo.",
      },
      :comments => {
        :commit => "en el commit %{sha1}",
        :permalink => '<abbr title="permalink para este comentario">#</abbr>',
        :add_title => "Agregue un nuevo commentario",
        :body => "Comentario",
        :add => "Agregar el comentario",
        :page_title => "Comentarios en %{repo}",
        :diff => "Diferencia de commits",
        :total => "(%{total}) comentarios",
        :page_title_2 => "Comentarios sobre %{title}",
        :page_title_3 => "Comentarios para el repositorio &quot;%{repo}&quot; en %{title}",
      },
      :commits => {
        :date => "Fecha",
        :committer => "Committer",
        :author => "Autor",
        :sha1 => "SHA1 del commit",
        :tree_sha1 => "SHA1 del árbol",
        :page_title => "Commit en %{repo} en %{title}",
        :title => "Commit %{commit}",
        :message => "Este es el commit inicial en este repositorio, <a href=\"%{path}\">navegue el estado inicial del árbol</a>.",
      },
      :sessions => {
        :login => "Entrar",
        :label => "Correo electrónico o cambiar a OpenID",
        :passwd => "Contraseña",
        :openid => "OpenID o cambiar a correo electrónico",
        :remember => "Recordarme",
        :submit => 'Entrar',
        :register => "Registrarse",
        :forgot => "¿Olvidó su contraseña?",
      },
      :searches => {
        :search => "Búsqueda",
        :hint => %Q{ej. 'wrapper', 'category:python' o '"document database"'},
        :page_title => %Q{Búsqueda por "%{term}"},
        :no_results => "Disculpe, no se han encontrado resultados con %{term}",
        :found => {
          :one => "Se encontró %{count} resultado en %{time}ms",
          :other => "Se encontraron %{count} resultados en %{time}ms",
        },
      },
      :trees => {
        :page_title => "Árbol para %{repo} en %{title}",
        :title => "Árbol para el repositorio %{repo} en %{title}",
        :download => "Descargar como un archivo comprimido (tar.gz)",
      },
      :repos => {
        :overview => "Resumen",
        :commits => "Commits",
        :tree => "Árbol de código fuente",
        :comments => "(%{count}) comentarios",
        :requests => "(%{count}) solicitudes de merge",
        :public_url => "URL pública para clonar",
        :more_info => "Más información…",
        :help_clone => "Puede clonar este repositorio con el siguiente comando",
        :help_clone_http => "note que clonar mediante HTTP es un poco más lento, pero útil si está detrás de un firewall",
        :http_url => "URL para clonar mediante HTTP",
        :push_url => "URL para publicar (Push)",
        :owner => "dueño",
        :confirm_delete => "Por favor confirme que desea borrar el %{repo} en %{title}",
        :message_delete => "Una vez que presione este botón el repositorio será borrado",
        :btn_delete => "SÍ, estoy seguro de que quiero borrar este repositorio para siempre",
        :page_title => "Repositorios en %{repo}",
        :title => "Repositorios",
        :commits => "Commits",
        :tree => "Árbol",
        :activities => { :one => "actividad", :other => "actividades" },
        :branches => { :one => "branch", :other => "branches" },
        :authors => { :one => "autor", :other => "autores" },
        :name => %Q{Nombre <small>(ej "%{name}-sandbox", "performance-fixes", etc)</small>},
        :btn_clone => "Clonar el repositorio",
        :back => "Volver al repositorio",
        :show_page_title => "%{repo} en %{title}",
        :show_title => "Repositorio &quot;%{repo}&quot; en %{title}",
        :activities => "Actividades",
        :clone_of => "Clon de",
        :created => "Creado",
        :btn_request => "Solicitar un merge",
        :btn_add_committer => "Agregar un committer",
        :btn_delete_repo => "Borrar el repositorio",
        :committers => "Committers",
        :remove => "Quitar",
        :create_title => "Crear un clon de <a href=\"%{clone_url}\">%{clone_name}</a> <small>en <a href=\"%{project_url}\">%{project_name}</a></small>",
        :clone_note => %Q{
          <em><strong>Nota:</strong> Los clones que no han tenido actualizaciones en 7
          días son borrados automáticamente (para evitar que el proyecto termine teniendo
          un montón de repositorios vacíos), así que es una buena idea esperar para
          crear el cln aquí hasta tener algo para publicar.</em>
        },
      },
      :projects => {
        :title => "Proyectos",
        :back => "Volver a la pantalla de edición",
        :hint => %Q{Se permite <a href="http://daringfireball.net/projects/markdown/">Markdown</a> y HTML básico},
        :categories => "Categorías",
        :delete => "Borrar proyecto",
        :delete_title => "Por favor confirme el borrado de %{title}",
        :delete_message => "Una vez que presione este botón el proyecto será borrado",
        :delete_btn => "SÍ, estoy seguro de que quiero borrar este repositorio para siempre",
        :edit => "Editar el proyecto",
        :update_title => "Actualizar %{link}",
        :new => "Nuevo proyecto",
        :popular => "Categorías populares",
        :new_title => "Crear un nuevo proyecto",
        :new_hint => %Q(Junto con el proyecto se creará también un repositorio "mainline". De esta forma usted podrá comenzar a trabajar en seguida.),
        :create => "Crear proyecto",
        :settings => "Configuración del proyecto",
        :labels => "Etiquetas",
        :license => "Licencia",
        :owner => "Dueño",
        :created => "Creado",
        :website => "Sitio web en ",
        :mailing => "Lista de correos en ",
        :bugtracker => "Administrador de errores en ",
        :repos => "Repositorios",
      },
      :merges => {
        :info => {
          :target_repos => "El repositorio con el que desea que este repositorio sea mezclado",
          :target_branch => "El branch donde desea que sus cambios sean mezclados",
          :source_branch => "El branch desde donde desea que el repositorio destino tome sus cambios para mezclar",
          :proposal => "Un breve resumen de sus cambios",
        },
        :summary_tile => "%{source} ah solicitado un merge con %{target}",
        :review => "Revisar la solicitud de merge &#x2192;",
        :page_title => "Solicitudes de merge en %{repo}",
        :hint => %Q{Una "solicitud de merge" es una notificación de un repositorio a otro, para indicar que se desea mezclar sus cambios.},
        :no_merge => "Aún no hay solicitudes de merge",
        :create_title => "Crear una solicitud de merge",
        :create_btn => "Crear una solicitud de merge",
        :show_title => "Revisando la solicitud de merge %{source} &#x2192; \"%{target}\"",
        :update_btn => "Actualizar solicitud de merge",
        :help => "La forma recomendada de mezclar estos cambios es hacer un pull de los mismos en un branch local para revisarlos y entonces mezclarlos al master:",
        :commits => "Commits que serían mezclados",
      },
      :committers => {
        :title => "Otorgar derechos de commit a un usuario para %{repo}",
        :login => "Usuario existente <small>(busca-mientras-escribe)</small>",
        :add => "Agregar como committer",
      },
      :common => {
        :confirm => "¿Está seguro?",
        :create => "Crear",
        :save => "Guardar",
        :delete => "borrar",
        :add => "Agregar",
        :yes => "Sí",
        :no => "No",
        :back => "Volver",
        :signup => 'Registrarse',
        :toggle => "Cambiar",
        :none => "ningúno",
        :update => "Actualizar",
        :cancel => "cancelar",
        :or => "o",
      },
    },
    :date => {
      :formats => {
        :long_ordinal => lambda { |date| "#{date.day} de %B de %Y" },
        :default => "%d/%m/%Y",
        :short => lambda { |date| "#{date.day} %b" },
        :long => lambda { |date| "#{date.day} de %B de %Y" },
        :only_day => "%e",
      },
      :day_names => %w(Domingo Lunes Martes Miércoles Jueves Viernes Sábado),
      :abbr_day_names => %w(Dom Lon Mar Mié Jue Vie Sáb),
      :month_names => [nil] + %w(Enero Febrero Marzo Abril Mayo Junio Julio Agosto Setiembre Octubre Noviembre Diciembre),
      :abbr_month_names => [nil] + %w(Ene Feb Mar Abr May Jun Jul Ago Set Oct Nov Dic),
      :order => [:day, :month, :year],
    },
    :time => {
      :formats => {
        :long_ordinal => lambda { |time| "#{time.day} de %B de %Y %H:%M" },
        :default => lambda { |time| "%A, #{time.day} de %B de %Y, %H:%M hs" },
        :time => "%H:%M hs",
        :short => lambda { |time| "#{time.day}/%m, %H:%M hs" },
        :long => lambda { |time| "%A, #{time.day} de %B de %Y, %H:%M hs" },
        :only_second => "%S",
        :human => "%A, %d de %B %Y",
        :short_time => "%H:%M",
        :datetime => {
          :formats => {
            :default => "%Y-%m-%dT%H:%M:%S%Z",
          },
        },
      },
      :time_with_zone => {
        :formats => {
          :default => lambda { |time| "%Y-%m-%d %H:%M:%S #{time.formatted_offset(false, 'UTC')}" }
        },
      },
      :am => '',
      :pm => '',
    },
    # date helper distancia en palabras
    :datetime => {
      :distance_in_words => {
        :half_a_minute => 'medio minuto',
        :less_than_x_seconds => {
          :one => 'menos de un segundo',
          :other => 'menos de %{count} segundos'
        },
        :x_seconds => {
          :one => '1 segundo',
          :other => '%{count} segundos'
        },
        :less_than_x_minutes => {
          :one => 'menos de un minuto',
          :other => 'menos de %{count} minutos'
        },
        :x_minutes => {
          :one => '1 minuto',
          :other => '%{count} minutos'
        },
        :about_x_hours => {
          :one => 'aproximadamente 1 hora',
          :other => 'aproximadamente %{count} horas'
        },
        :x_days => {
          :one => '1 dia',
          :other => '%{count} dias'
        },
        :about_x_months => {
          :one => 'aproximadamente 1 mes',
          :other => 'aproximadamente %{count} meses'
        },
        :x_months => {
          :one => '1 mes',
          :other => '%{count} meses'
        },
        :about_x_years => {
          :one => 'aproximadamente 1 año',
          :other => 'aproximadamente %{count} años'
        },
        :over_x_years => {
          :one => 'más de 1 año',
          :other => 'más de %{count} años'
        }
      }
    },

    # números
    :number => {
      :format => {
        :precision => 3,
        :separator => ',',
        :delimiter => '.'
      },
      :currency => {
        :format => {
          :unit => '$',
          :precision => 2,
          :format => '%u %n'
        }
      }
    },

    :activerecord => {
      :models => {
        :user => {
          :one => "Usuario",
          :other => "Usuarios" ,
        },
        :merge_request => {
          :one => "Solicitud de merge",
          :other => "Solicitudes de merge",
        },
        :project => {
          :one => "Proyecto",
          :other => "Proyectos",
        },
        :comment => {
          :one => "Comentario",
          :other => "Comentarios",
        },
        :repositories => {
          :one => "Repositorio",
          :other => "Repositorios",
        },
        :keys => {
          :one => "Llave",
          :other => "Llaves",
        },
      },
      :attributes => {
        :user => {
          :login => "Login",
          :email => "Correo electrónico",
          :current_password => "Contraseña actual",
          :password => "Contraseña",
          :password_confirmation => "Confirmación de contraseña",
          :created_at => "Creado en",
          :updated_at => "Actualizado en",
          :activation_code => "Código de activación",
          :activated_at => "Activado en",
          :fullname => "Nombre completo",
          :url => "URL",
        },
        :merge_request => {
          :target_repository_id => "Repositorio destino",
          :proposal => "Propuesta",
          :source_branch => "Branch de origen",
          :target_branch => "Branch de destino",
        },
        :project => {
          :title => "Título",
          :description => "Descripción (obligatoria)",
          :slug => "Slug (para URLs, etc)",
          :license => "Licencia",
          :home_url => "URL del sitio principal (ej Rubyforge, etc)",
          :mailinglist_url => "URL a la Lista de correos (si tiene)",
          :bugtracker_url => "URL al administrador de errores (si tiene)",
          :tag_list => "Categorías (separadas por espacios)",
        },
        :comment => {
          :body => "Comentario",
        },
        :repository => {
          :name => "Nombre",
          :ready => "Preparado",
        },
        :keys => {
          :key => "Llave",
          :ready => "Preparada",
        },
      },
      :errors => {
        :template => {
          :header => {
            :one => "%{model} no puede ser guardado: 1 error",
            :other => "%{model} no puede ser guardado: %{count} errores."
          },
          :body => "Por favor, revise los siguientes campos:"
        },
        :messages => {
          :inclusion => "no está incluido en la lista",
          :exclusion => "no está disponible",
          :invalid => "no es válido",
          :confirmation => "no coincide con la confirmación",
          :accepted => "debe ser aceptado",
          :empty => "no puede estar vacío",
          :blank => "no puede estar vacío",
          :too_long => "es muy largo (no más de %{count} caracteres)",
          :too_short => "es muy corto (no menos de %{count} caracteres)",
          :wrong_length => "no tiene el tamaño correcto (debe tener %{count} caracteres)",
          :taken => "no está disponible",
          :not_a_number => "no es un número",
          :greater_than => "debe ser mayor que %{count}",
          :greater_than_or_equal_to => "debe ser mayor o igual a %{count}",
          :equal_to => "debe ser igual a %{count}",
          :less_than => "debe ser menor que %{count}",
          :less_than_or_equal_to => "debe ser menor o igual a %{count}",
          :odd => "debe ser impar",
          :even => "debe ser par"
        }
      }
    }
  }
}
