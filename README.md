# MySuperApp

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser

## Functionality

The project is built with Phoenix, LiveView, and integrates with Oban for background job processing. It supports the following core functionalities:

**Admin Panel**: An administrative interface to manage users, roles, posts, images, and sites. The panel allows the creation, editing, and deletion of entities with role-based access control.

**User Management**: The admin panel provides features for managing user profiles, including the ability to assign roles and permissions.

**Role-Based Access Control**: The project implements role-based access control (RBAC) for different users. Administrators can create and manage roles with specific permissions to control access to different resources.

**Image Upload**: Integration with AWS S3 allows users to upload and manage images. Images are securely stored in the cloud and linked to specific posts or entities.

**Post Management**: Admins can create, edit, and delete posts. The posts can be associated with images and other metadata. The system supports creating and managing content for a dynamic website.

**Mailing System**: Utilizes Mailjet for sending emails. Email notifications can be triggered through Oban background jobs, ensuring that email sending does not block the application.

**Background Job Processing**: Oban is used to handle background tasks such as sending emails, generating reports, or any other time-consuming operations that need to be processed asynchronously.

**Database**: The project uses PostgreSQL for data storage. It stores information about users, roles, posts, images, and other application data.

LiveView Support: The user interface makes extensive use of Phoenix LiveView to provide real-time, interactive features without the need for client-side JavaScript frameworks.

### Video presentation

[![MySuperApp presentation](https://img.youtube.com/vi/WEDggNVOppA/0.jpg)](https://www.youtube.com/watch?v=WEDggNVOppA)
