let communityRegex =
  /^(?:https|lemmiosapp):\/\/([a-zA-Z\-\.]+?)\/c\/([a-z_]+)(@[a-z\-.]+)?$/;
let userRegex =
  /^(?:https|lemmiosapp):\/\/([a-zA-Z\-\.]+?)\/u\/([0-9a-zA-Z_]+)(@[a-z\-.]+)?$/;
let postRegex = /^(?:https|lemmiosapp):\/\/([a-zA-Z\-\.]+?)\/post\/([0-9]+)$/;
let commentRegex =
  /^(?:https|lemmiosapp):\/\/([a-zA-Z\-\.]+?)\/comment\/([0-9]+)$/;

const observeUrlChange = () => {
  let oldHref = document.location.href;
  const body = document.querySelector("body");
  const observer = new MutationObserver((mutations) => {
    if (oldHref !== document.location.href) {
      oldHref = document.location.href;
      openIfNeeded();
    }
  });
  observer.observe(body, { childList: true, subtree: true });
};

function openIfNeeded() {
  if (postRegex.test(document.location.href)) {
    let url = new URL(document.location.href);
    fetch(
      `${url.protocol}//${url.hostname}/api/v3/post?id=${
        url.pathname.split("/")[2]
      }`
    ).then((response) => {
      response.json().then((data) => {
        let postUrl = new URL(data.post_view.post.ap_id);
        postUrl.protocol = "lemmiosapp:";
        window.location.href = postUrl;
      });
    });
  } else if (communityRegex.test(document.location.href)) {
    let url = new URL(document.location.href);
    fetch(
      `${url.protocol}//${url.hostname}/api/v3/community?name=${
        url.pathname.split("/")[2]
      }`
    ).then((response) => {
      response.json().then((data) => {
        console.log(data.community_view.community);
        let communityUrl = new URL(data.community_view.community.actor_id);
        communityUrl.protocol = "lemmiosapp:";
        window.location.href = communityUrl;
      });
    });
  } else if (userRegex.test(document.location.href)) {
    let url = new URL(document.location.href);
    fetch(
      `${url.protocol}//${url.hostname}/api/v3/user?username=${
        url.pathname.split("/")[2]
      }`
    ).then((response) => {
      response.json().then((data) => {
        console.log(data.person_view.person);
        let userUrl = new URL(data.person_view.person.actor_id);
        userUrl.protocol = "lemmiosapp:";
        window.location.href = userUrl;
      });
    });
  } else if (commentRegex.test(document.location.href)) {
    let url = new URL(document.location.href);
    fetch(
      `${url.protocol}//${url.hostname}/api/v3/comment?id=${
        url.pathname.split("/")[2]
      }`
    ).then((response) => {
      response.json().then((data) => {
        let commentUrl = new URL(data.comment_view.comment.ap_id);
        commentUrl.protocol = "lemmiosapp:";
        window.location.href = commentUrl;
      });
    });
  }
}

openIfNeeded();
window.onload = observeUrlChange;
