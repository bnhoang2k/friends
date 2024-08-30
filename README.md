## Introduction

As I grew older, I noticed that work, school, and life in general became more demanding; to build the future that I envisioned for myself, I needed to work harder and harder to start my career off on the right foot. However, grinding came at the cost of my relationships; the more I worked, the more I pushed others aside, and the more depressed I became.

I knew I needed to find a better balance between work and my personal life. On top of that, with how competitive the CS field is, I also needed a way to stand out. So, I decided to create a project that could help me tackle both of these challenges.

My idea was simple: create a social app that helps maintain relationships. The basic concept was that users could create a profile, add their friends, and set up reminders to check in on them. This way, I could stay connected with friends and family without worrying about forgetting.

Initially, it seemed pretty basic, so I decided to leverage the power of LLMs to create more personalized and advanced plans tailored to the specific person I’m hanging out with. After all, everyone is different, with unique preferences and interests, so it made sense to make the experience more customized. The app would store all the "hangouts" you've had with people, feed this data into an LLM, and provide specialized suggestions based on past interactions.

The app is written in Swift and uses Firebase for backend services like authentication, Firestore for managing user and hangout data, and Cloud Storage. I’m also integrating LLMs into the app, using Firebase to handle data processing and storage, making it a seamless and scalable solution.

## Why Firebase?

Firebase is Google's mobile development platform that enables quick deployment and scalability, making it an easy choice for my app. It integrates seamlessly with Google Cloud products like Cloud Firestore, Cloud Functions, and Cloud Storage, allowing both server and client SDKs to access the same data, which simplifies front-end and back-end integration. Additionally, Firebase and Google Cloud share unified billing, charged on a pay-as-you-go basis. Currently, my project is small and fits within Firebase's [free tier](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans), but planning for scalability now ensures a smooth transition as the app grows.

### Firebase Authentication

Authentication is a critical component of any application, ensuring secure and seamless access for users. I chose Firebase Authentication because it supports various sign-in methods, including email/password, Google, and Apple, which makes onboarding flexible and user-friendly. With Firebase, I can easily manage user sessions, handle password resets, and integrate secure authentication flows with minimal setup. This not only speeds up development but also provides robust security features like OAuth tokens and multi-factor authentication, giving users peace of mind while keeping their accounts safe. Below is an image demonstrating how Firebase Authentication integrates with my Swift app:

<table align="center">
  <tr>
    <td><img src="https://github.com/bnhoang2k/friends/raw/main/GitHub%20Resources/App%20Screenshots/Sign%20In%20Page.png" alt="Sign in page" width="300"></td>
    <td><img src="https://github.com/bnhoang2k/friends/raw/main/GitHub%20Resources/Firebase%20Screenshots/Authentication%20Dashboard.png" alt="Firebase Authentication Dashboard" width="700"></td>
  </tr>
</table>

The Firebase Authentication dashboard provides valuable information, such as user emails, the sign-up providers they used, and account creation dates. This makes it easy for me to manage and manipulate user data effectively.

### Database Management

Outside of authentication, Firebase streamlines data management with Cloud Firestore. Firestore is a scalable, NoSQL cloud database that supports real-time syncing and offline capabilities, making it ideal for a social app where data must be fast and reliable. Its flexible document-based model allows for efficient data structuring, and its powerful querying capabilities enable complex data retrieval without sacrificing performance. Additionally, Firestore’s integration with Firebase Authentication simplifies securing user-specific data, ensuring that each user's information is private and accessible only to them.

### Serverless LLM Hosting

To integrate an LLM into the application, I explored several different routes. My priority was to keep the app fast and responsive, as I didn't want users waiting for queries to and from the LLM. With this in mind, I needed to decide where to 'host' the LLM. The options I considered included:

- Swift's Core ML Framework
- Using my server, creating an API, and reading to and from it.
- Going serverless.

| Option | Description | Pros | Cons |
|-------------------|-------------------|----------------------------|----------------------------|
|Swift's Core ML Framework | Core ML can be used to integrate machine learning models directly into the application. Core ML itself provides a unified representation for all models. <br> The app will use Core ML APIs and user data to make predictions, and train and fine-tune models, all on the device itself. | - Embeds the model directly into the app and device. <br> - Provides low latency and offline capabilities. | - Increases app size significantly. <br> Device limitations can impact model size, speed, and accuracy. <br> - Limited computational resources compared to server-based solutions. <br> -  Uploading and tuning custom LLMs is restricted by Core ML and Swift's architecture.|
|Use my server with custom LLMs | Setting up my own Ubuntu server allows me to host any LLMs I want on my infrastructure. I have full control over the configuration and API architecture. |- Complete control over server environment, configurations, and security measures. <br> - Ability to fine-tune the LLM and optimize it specifically for my application's needs. <br> - Can be scaled based on traffic and computational needs depending on server resources. <br> - Allows management of data storage and handling securely, keeping sensitive data on my own controlled infrastructure. | - High cost; running computationally expensive LLMs requires significant resources, and scalability can further drive up costs. <br> - Hardware limitations may restrict the performance and capacity of the LLM. <br> - Requires expertise in server management and security to ensure proper setup and maintenance. |
|Serverless / Cloud Computing|Using a serverless architecture involves deploying the LLM on cloud platforms that automatically manage server resources and scale. This approach leverages services like AWS Lambda, Google Cloud Functions, or Azure Functions, where the cloud provider handles the infrastructure. I only need to deploy the code, and the service will automatically scale based on demand, without the need for manual server management or upfront hardware investments.| - Scalability: Automatically scales with the number of requests, handling varying loads without manual intervention. <br> - Cost-Efficient: Only pay for the compute time and resources (e.g., reads/writes) that your code uses, making it very cost-effective for smaller apps. <br> - No Server Management: Eliminates the need to manage servers, reducing operational overhead. <br> - Simplifies Deployment: Allows for quick iterations and updates, streamlining the deployment process.  | - Limited Execution Time: Serverless functions have time limits (e.g., AWS Lambda has a 15-minute limit), which may cause longer or more complex tasks to fail. <br> - Complex Debugging and Monitoring: Requires learning specialized tools and approaches, which can complicate debugging and monitoring. <br> - Limited Control: Less control over the underlying infrastructure and environment settings. <br> - Vendor Lock-In: Tightly integrates with a specific provider's platform, making it harder to switch vendors or migrate to a different architecture. |

Initially, using my server was highly appealing due to the control it offered. I set up an Ubuntu server, installed Ollama, and started testing various models from HuggingFace. I also wrote an API in Flask to access these models. While the initial setup was straightforward, I soon encountered significant issues.

I drew inspiration from OpenAI's ChatGPT app, particularly in how they manage so many users. Their serverless architecture seemed to be key to handling large-scale traffic efficiently. This led me to question my approach—what if my app gained a large user base? Would I need to create separate instances for each user? With even the simplest models consuming 8 GB of memory and my server having only 32 GB, it was clear that scaling would be problematic.

Additionally, the models I could use were severely limited in capability, forcing me to constantly choose between speed and correctness. I also faced networking issues; the server wasn’t accessible outside of my local network without additional configuration.

Prioritizing speed, scalability, and correctness, I decided to switch to a serverless architecture, which better suited my needs for handling large-scale user traffic without sacrificing performance. Initially, Microsoft Azure was tempting, but the issue of vendor lock-in made me cautious; switching cloud providers later in development would be complex and challenging. That’s when I recalled that Firebase is part of Google Cloud Platform.

Exploring Firebase, I wondered if Google Cloud services could easily integrate with the Firebase project I already had in progress. Fortunately, I [struck gold](https://extensions.dev/extensions/googlecloud/firestore-multimodal-genai) when I discovered that Firebase supports extensions from Google Cloud services, allowing seamless integration into my existing setup. All it required was installing the extension into my project and obtaining an API key from Google AI Studio. The extension seamlessly integrated with the existing database in my project and automatically generated the responses for me. This integration wasn’t just about convenience—it was about aligning with industry standards for scalable, modern applications. Going serverless was strategic in a couple of senses:

- I wanted my app to be fast and responsive, no matter how many people used it. By going serverless, I’m using Google Cloud’s powerful infrastructure, which means my app can handle spikes in traffic without breaking a sweat. It’s not just about convenience; it’s about delivering the best experience for my users.
- Managing servers can be a huge time sink, pulling me away from what I care about; building and improving my app. Switching to serverless lets me focus on developing features, fixing bugs, and pushing updates quickly. It’s about working smarter, not harder.
-  As someone just starting, every dollar counts. Serverless is perfect because it scales with usage, so I’m only paying for what I use. This approach keeps costs predictable and manageable, which is a big deal when you’re trying to grow without burning through resources.
- Security is non-negotiable, especially when handling user data. Google Cloud and Firebase come with built-in security features that I would’ve had to implement and constantly manage on my server. This switch lets me provide a secure app without the extra stress of maintaining those standards myself.

Most importantly, I didn’t just want my app to work today; I wanted it to be ready for whatever comes next. By using serverless and cloud-native tools, I’m setting it up for easy scaling and integration with other cutting-edge technologies down the line. It’s about future-proofing the app so it can grow alongside its users.
